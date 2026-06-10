# Product Definition: Synapse Collaborative 3D Design Platform

## Core Vision
Synapse is a professional-grade, web-native collaborative 3D design platform. It empowers design teams, product creators, and architects to co-create, visualize, and present 3D spaces and interactive scenes directly in their browsers or through native desktop clients. By coupling a highly polished **2D editor workspace UI** built in Flutter with a concurrent, high-performance **3D rendering and physics simulation core** written in Rust (Bevy 3D), Synapse delivers desktop-class performance, instant multiplayer synchronization, and absolute cross-platform freedom.

## Main Target Audiences
- **Industrial & Smart Space Designers**: For designing and laying out interactive 3D rooms, digital twins, and retail floor layouts.
- **Product Presentation Designers**: For constructing rich, animated, and interactive 3D product previews, packaging designs, and digital showrooms.
- **3D Prototypers & Creators**: For collaborative scene composition, lighting design, and asset arrangement with zero-install overhead.

## Key Product Features
1. **Real-Time Multiplayer Collaboration**: True simultaneous co-creation in a shared 3D canvas, featuring real-time collaborative cursor presence, active entity lock indicators, and live sync at sub-millisecond latencies.
2. **Interactive 3D Workspace & Viewport**: Built on WebGPU/Metal, providing professional CAD-level camera controllers, immediate-mode grids, coordinate axes, and high-performance 3D transform gizmos (Translation, Rotation, Scale) for direct model manipulation.
3. **Slick 2D Property Panel & Scene Tree**: Driven by Flutter, featuring a complete resizable Scene Tree Hierarchy, multi-track Animation Timelines, and a Property Inspector for configuring transform parameters, multi-map PBR materials, and advanced light source properties.
4. **Zero-Copy Native FFI Channel**: Underpinned by a synchronous, zero-copy FFI bridge between Dart and Rust, preventing garbage collection pauses and ensuring smooth 120Hz interface rendering.
5. **Universal SaaS Distribution**: Accessible instantly via WebGL2/WebGPU browsers through highly optimized WebAssembly and downloadable as native binaries for macOS, Windows, and Linux desktops from the same source.
