import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/state/viewport_state.dart';

class BevyViewport extends ConsumerStatefulWidget {
  const BevyViewport({super.key});

  @override
  ConsumerState<BevyViewport> createState() => _BevyViewportState();
}

class _BevyViewportState extends ConsumerState<BevyViewport> {
  double _lastWidth = 0;
  double _lastHeight = 0;

  @override
  void dispose() {
    // Gracefully clean up native textures on viewport dispose
    Future.microtask(() {
      ref.read(bevyViewportStateProvider.notifier).dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportState = ref.watch(bevyViewportStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Perform lazy initialization once the layout dimensions are known
        if (!viewportState.initialized) {
          if (width > 0 && height > 0) {
            _lastWidth = width;
            _lastHeight = height;
            Future.microtask(() {
              ref.read(bevyViewportStateProvider.notifier).init(width, height);
            });
          }
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00FFFF)),
          );
        }

        // Handle dynamic resizing of the viewport widget in real-time
        if (width != _lastWidth || height != _lastHeight) {
          _lastWidth = width;
          _lastHeight = height;
          Future.microtask(() {
            ref.read(bevyViewportStateProvider.notifier).resize(width, height);
          });
        }

        return Container(
          color: Colors.black,
          child: Texture(textureId: viewportState.textureId),
        );
      },
    );
  }
}
