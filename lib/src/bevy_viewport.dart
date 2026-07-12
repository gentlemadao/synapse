import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/state/viewport_state.dart';

class BevyViewport extends ConsumerStatefulWidget {
  const BevyViewport({super.key});

  @override
  ConsumerState<BevyViewport> createState() => _BevyViewportState();
}

class _BevyViewportState extends ConsumerState<BevyViewport> {
  // Cache the viewport notifier to avoid riverpod element asserted-not-disposed lifecycle errors
  late final BevyViewportState _stateNotifier;

  @override
  void initState() {
    super.initState();
    _stateNotifier = ref.read(bevyViewportStateProvider.notifier);
  }

  @override
  void dispose() {
    // Gracefully clean up native textures on viewport dispose synchronously while unmounting
    _stateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportState = ref.watch(bevyViewportStateProvider);

    // Initialize once with a cinematic, wide high-definition 16:10 aspect-ratio render buffer (1600x1000px).
    // By eliminating the dynamic LayoutBuilder completely, we prevent high-frequency layout recalculations
    // and momentary zero-width constraints during active resizing, completely eliminating any flickering or disappearing.
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
      // FittedBox automatically performs high-performance, GPU-accelerated,
      // distortion-free uniform scaling of our widescreen native texture with 0 rebuilds!
      child: FittedBox(
        fit: BoxFit
            .contain, // Guarantee exact geometric aspect-ratio bounds (no stretch!)
        child: SizedBox(
          width: viewportState.width,
          height: viewportState.height,
          child: Texture(textureId: viewportState.textureId),
        ),
      ),
    );
  }
}
