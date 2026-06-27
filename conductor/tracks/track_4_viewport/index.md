# Track 4: Bevy GPU Viewport & Native Texture Sharing

## Overview
This track covers the design, implementation, and verification of a high-performance, hardware-accelerated 3D viewport in Flutter. By configuring a headless Bevy (Rust) engine to render directly into an `IOSurface`-backed `CVPixelBuffer` on macOS, and sharing the Metal texture context with Flutter's Texture Registry, we achieve a 100% zero-copy, 120Hz smooth 3D CAD viewport.

## Key Files
- [Specification](./spec.md)
- [Implementation Plan](./plan.md)
- [Metadata](./metadata.json)
