import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/state/viewport_state.dart';
import 'package:synapse/src/rust/api/simple.dart' as rust;

class BevyViewport extends ConsumerStatefulWidget {
  const BevyViewport({super.key});

  @override
  ConsumerState<BevyViewport> createState() => _BevyViewportState();
}

class _BevyViewportState extends ConsumerState<BevyViewport> {
  late final BevyViewportState _stateNotifier;
  Timer? _webFrameTimer;
  ui.Image? _currentWebFrame;
  bool _isRenderingFrame = false;

  @override
  void initState() {
    super.initState();
    _stateNotifier = ref.read(bevyViewportStateProvider.notifier);
    if (kIsWeb) {
      _startWebRenderLoop();
    }
  }

  void _startWebRenderLoop() {
    // Schedule periodic ticks at ~60fps (16ms per frame)
    _webFrameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _tickWebFrame();
    });
  }

  void _tickWebFrame() {
    if (!mounted || _isRenderingFrame) return;

    final viewportState = ref.read(bevyViewportStateProvider);
    if (!viewportState.initialized) return;

    _isRenderingFrame = true;

    try {
      final width = viewportState.width.toInt();
      final height = viewportState.height.toInt();

      // Synchronously call Rust to render the frame to BGRA bytes
      final bytes = rust.renderFrameWasm(
        viewportId: BigInt.from(1),
        width: width,
        height: height,
      );

      // Asynchronously decode the pixel buffer into a GPU-backed ui.Image
      ui.decodeImageFromPixels(bytes, width, height, ui.PixelFormat.bgra8888, (
        ui.Image image,
      ) {
        if (mounted) {
          setState(() {
            _currentWebFrame?.dispose(); // Instantly free old texture resources
            _currentWebFrame = image;
          });
        } else {
          image.dispose();
        }
        _isRenderingFrame = false;
      });
    } catch (e) {
      debugPrint('[BevyViewport Web] Error rendering frame: $e');
      _isRenderingFrame = false;
    }
  }

  @override
  void dispose() {
    _webFrameTimer?.cancel();
    _currentWebFrame?.dispose();
    _stateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportState = ref.watch(bevyViewportStateProvider);

    if (!viewportState.initialized) {
      Future.microtask(() {
        _stateNotifier.init(1600, 1000);
      });
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00FFFF)),
      );
    }

    return Container(
      color: const Color(0xFF090A0F),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: viewportState.width,
          height: viewportState.height,
          child: kIsWeb
              ? CustomPaint(
                  painter: _WebFramePainter(_currentWebFrame),
                  size: Size(viewportState.width, viewportState.height),
                )
              : Texture(textureId: viewportState.textureId),
        ),
      ),
    );
  }
}

class _WebFramePainter extends CustomPainter {
  final ui.Image? image;
  _WebFramePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WebFramePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
