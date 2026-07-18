import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synapse/src/rust/api/simple.dart' as rust;

part 'viewport_state.g.dart';

class ViewportState {
  final int textureId;
  final int iosurfaceId;
  final int viewportHandle;
  final double width;
  final double height;
  final bool initialized;

  ViewportState({
    required this.textureId,
    required this.iosurfaceId,
    required this.viewportHandle,
    required this.width,
    required this.height,
    required this.initialized,
  });

  factory ViewportState.initial() => ViewportState(
    textureId: -1,
    iosurfaceId: 0,
    viewportHandle: 0,
    width: 0,
    height: 0,
    initialized: false,
  );

  ViewportState copyWith({
    int? textureId,
    int? iosurfaceId,
    int? viewportHandle,
    double? width,
    double? height,
    bool? initialized,
  }) {
    return ViewportState(
      textureId: textureId ?? this.textureId,
      iosurfaceId: iosurfaceId ?? this.iosurfaceId,
      viewportHandle: viewportHandle ?? this.viewportHandle,
      width: width ?? this.width,
      height: height ?? this.height,
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

    if (kIsWeb) {
      try {
        rust.initViewportWasm(
          viewportId: BigInt.from(1),
          width: width.toInt(),
          height: height.toInt(),
        );
        state = ViewportState(
          textureId: 1,
          iosurfaceId: 0,
          viewportHandle: 1,
          width: width,
          height: height,
          initialized: true,
        );
      } catch (e) {
        debugPrint('[Viewport State] Error initializing WASM viewport: $e');
      }
      return;
    }

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
          width: width,
          height: height,
          initialized: true,
        );
      }
    } catch (e) {
      debugPrint('[Viewport State] Error initializing native texture: $e');
    }
  }

  Future<void> resize(double width, double height) async {
    if (!state.initialized) return;

    if (kIsWeb) {
      try {
        rust.resizeViewportWasm(
          viewportId: BigInt.from(1),
          width: width.toInt(),
          height: height.toInt(),
        );
        state = state.copyWith(width: width, height: height);
      } catch (e) {
        debugPrint('[Viewport State] Error resizing WASM viewport: $e');
      }
      return;
    }

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
        state = state.copyWith(
          iosurfaceId: result['iosurfaceId'] as int,
          width: width,
          height: height,
        );
      }
    } catch (e) {
      debugPrint('[Viewport State] Error resizing native texture: $e');
    }
  }

  Future<void> dispose() async {
    if (!state.initialized) return;

    if (kIsWeb) {
      state = ViewportState.initial();
      return;
    }

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
