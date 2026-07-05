import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/state/viewport_state.dart';

class BevyViewport extends ConsumerStatefulWidget {
  const BevyViewport({super.key});

  @override
  ConsumerState<BevyViewport> createState() => _BevyViewportState();
}

class _BevyViewportState extends ConsumerState<BevyViewport> {
  // Store the state notifier as a class field to safely dispose of it without using "ref" during unmounting
  late final BevyViewportState _viewportStateNotifier;

  @override
  void initState() {
    super.initState();
    _viewportStateNotifier = ref.read(bevyViewportStateProvider.notifier);
  }

  @override
  void dispose() {
    // Gracefully clean up native textures on viewport dispose safely using the saved class field
    _viewportStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportState = ref.watch(bevyViewportStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize once with a cinematic, wide high-definition 16:10 aspect-ratio render buffer (1600x1000px).
        // Decoupling FFI allocation from layout resizing completely eliminates texture stretching,
        // and guarantees 100% buttery-smooth, distortion-free graphics scaling on all desktop layouts.
        if (!viewportState.initialized) {
          Future.microtask(() {
            _viewportStateNotifier.init(1600, 1000);
          });
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00FFFF)),
          );
        }

        return Container(
          color: const Color(0xFF090A0F),
          alignment: Alignment.center,
          // FittedBox performs GPU-accelerated, perfect uniform aspect-ratio scaling
          // of our fixed widescreen texture. The 3D scene will never stretch!
          child: FittedBox(
            fit: BoxFit
                .contain, // Keep exact geometric proportions (no stretching!)
            child: SizedBox(
              width: viewportState.width,
              height: viewportState.height,
              child: Texture(textureId: viewportState.textureId),
            ),
          ),
        );
      },
    );
  }
}
