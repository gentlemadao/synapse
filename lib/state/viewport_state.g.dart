// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewport_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BevyViewportState)
final bevyViewportStateProvider = BevyViewportStateProvider._();

final class BevyViewportStateProvider
    extends $NotifierProvider<BevyViewportState, ViewportState> {
  BevyViewportStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bevyViewportStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bevyViewportStateHash();

  @$internal
  @override
  BevyViewportState create() => BevyViewportState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ViewportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ViewportState>(value),
    );
  }
}

String _$bevyViewportStateHash() => r'31ea3b03dd1eff1051863d6c1d0c0bc523636db8';

abstract class _$BevyViewportState extends $Notifier<ViewportState> {
  ViewportState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ViewportState, ViewportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ViewportState, ViewportState>,
              ViewportState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
