import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_state.g.dart';

// Bevy Node model definition
class BevyNode {
  final String id;
  final String name;
  final String type;
  final double px, py, pz;
  final double scale;
  final Color color;
  final bool visible;

  BevyNode({
    required this.id,
    required this.name,
    required this.type,
    this.px = 0.0,
    this.py = 0.0,
    this.pz = 0.0,
    this.scale = 1.0,
    this.color = Colors.blueAccent,
    this.visible = true,
  });

  BevyNode copyWith({
    String? id,
    String? name,
    String? type,
    double? px,
    double? py,
    double? pz,
    double? scale,
    Color? color,
    bool? visible,
  }) {
    return BevyNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      px: px ?? this.px,
      py: py ?? this.py,
      pz: pz ?? this.pz,
      scale: scale ?? this.scale,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }
}

// 1. Riverpod generator for Active Selected Node Index
@riverpod
class SelectedNodeIndex extends _$SelectedNodeIndex {
  @override
  int build() {
    return 7; // Select the 3D chair by default
  }

  void select(int index) {
    state = index;
  }
}

// 2. Riverpod generator for Bevy Nodes list
@riverpod
class BevyNodes extends _$BevyNodes {
  @override
  List<BevyNode> build() {
    return [
      BevyNode(
        id: 'node_0',
        name: 'Walnut Floor',
        type: 'Cuboid',
        py: -0.84,
        scale: 1.0,
        color: const Color(0xFF3E2723),
      ),
      BevyNode(
        id: 'node_1',
        name: 'Slate Back-Left Wall',
        type: 'Cuboid',
        px: -1.5,
        py: 0.06,
        color: const Color(0xFF1F2937),
      ),
      BevyNode(
        id: 'node_2',
        name: 'Slate Back-Right Wall',
        type: 'Cuboid',
        py: 0.06,
        pz: -1.5,
        color: const Color(0xFF111827),
      ),
      BevyNode(
        id: 'node_3',
        name: 'Matte Coffee Table',
        type: 'Cuboid',
        px: 0.5,
        py: -0.77,
        pz: 0.5,
        color: const Color(0xFF374151),
      ),
      BevyNode(
        id: 'node_4',
        name: 'Smart Glowing Hub',
        type: 'Cuboid',
        px: 0.5,
        py: -0.64,
        pz: 0.5,
        color: Colors.cyanAccent,
      ),
      BevyNode(
        id: 'node_5',
        name: 'Floor Lamp Post',
        type: 'Cylinder',
        px: -1.1,
        py: -0.09,
        pz: -1.1,
        color: Colors.white70,
      ),
      BevyNode(
        id: 'node_6',
        name: 'Smart Glow Bulb',
        type: 'Sphere',
        px: -1.1,
        py: 0.66,
        pz: -1.1,
        color: const Color(0xFFFFD1A9),
      ),
      BevyNode(
        id: 'node_7',
        name: 'Model_Chair_01',
        type: 'GLB Mesh',
        scale: 1.2,
        color: Colors.blueAccent,
      ),
    ];
  }

  void updatePositionX(int index, double val) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(px: val) else state[i],
    ];
  }

  void updatePositionY(int index, double val) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(py: val) else state[i],
    ];
  }

  void updatePositionZ(int index, double val) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(pz: val) else state[i],
    ];
  }

  void updateScale(int index, double val) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(scale: val) else state[i],
    ];
  }

  void updateColor(int index, Color color) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(color: color) else state[i],
    ];
  }

  void setNodes(List<BevyNode> newNodes) {
    state = newNodes;
  }
}
