// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedNodeIndex)
final selectedNodeIndexProvider = SelectedNodeIndexProvider._();

final class SelectedNodeIndexProvider
    extends $NotifierProvider<SelectedNodeIndex, int> {
  SelectedNodeIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedNodeIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedNodeIndexHash();

  @$internal
  @override
  SelectedNodeIndex create() => SelectedNodeIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedNodeIndexHash() => r'945242ecb640ff003be3e5fce9c1e13147b9aae1';

abstract class _$SelectedNodeIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(BevyNodes)
final bevyNodesProvider = BevyNodesProvider._();

final class BevyNodesProvider
    extends $NotifierProvider<BevyNodes, List<BevyNode>> {
  BevyNodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bevyNodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bevyNodesHash();

  @$internal
  @override
  BevyNodes create() => BevyNodes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BevyNode> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BevyNode>>(value),
    );
  }
}

String _$bevyNodesHash() => r'f26194e6f5976420befd2cb12f19ddd41d6ec7ec';

abstract class _$BevyNodes extends $Notifier<List<BevyNode>> {
  List<BevyNode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<BevyNode>, List<BevyNode>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BevyNode>, List<BevyNode>>,
              List<BevyNode>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
