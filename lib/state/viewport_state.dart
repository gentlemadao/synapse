import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'viewport_state.g.dart';

class ViewportState {
  final int textureId;
  final int iosurfaceId;
  final int viewportHandle;
  final bool initialized;

  ViewportState({
    required this.textureId,
    required this.iosurfaceId,
    required this.viewportHandle,
    required this.initialized,
  });

  factory ViewportState.initial() => ViewportState(
    textureId: -1,
    iosurfaceId: 0,
    viewportHandle: 0,
    initialized: false,
  );

  ViewportState copyWith({
    int? textureId,
    int? iosurfaceId,
    int? viewportHandle,
    bool? initialized,
  }) {
    return ViewportState(
      textureId: textureId ?? this.textureId,
      iosurfaceId: iosurfaceId ?? this.iosurfaceId,
      viewportHandle: viewportHandle ?? this.viewportHandle,
      initialized: initialized ?? this.initialized,
    );
  }
}

@riverpod
class BevyViewportState extends _$BevyViewportState {
  static const _channel = MethodChannel('synapse/viewport');

  @override
  ViewportState build() {
    return ViewportState.initial();
  }

  Future<void> init(double width, double height) async {
    if (state.initialized) return;

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'initTexture',
        {'width': width.toInt(), 'height': height.toInt()},
      );

      if (result != null) {
        state = ViewportState(
          textureId: result['textureId'] as int,
          iosurfaceId: result['iosurfaceId'] as int,
          viewportHandle: result['viewportHandle'] as int,
          initialized: true,
        );
      }
    } catch (e) {
      debugPrint('[Viewport State] Error initializing native texture: $e');
    }
  }

  Future<void> resize(double width, double height) async {
    if (!state.initialized) return;

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'resizeTexture',
        {
          'textureId': state.textureId,
          'width': width.toInt(),
          'height': height.toInt(),
        },
      );

      if (result != null) {
        state = state.copyWith(iosurfaceId: result['iosurfaceId'] as int);
      }
    } catch (e) {
      debugPrint('[Viewport State] Error resizing native texture: $e');
    }
  }

  Future<void> dispose() async {
    if (!state.initialized) return;

    try {
      await _channel.invokeMethod('disposeTexture', {
        'textureId': state.textureId,
      });
      state = ViewportState.initial();
    } catch (e) {
      debugPrint('[Viewport State] Error disposing native texture: $e');
    }
  }
}
