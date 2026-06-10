# Track 1 Specification: Bootstrap

## Goal
Establish a fully functional, highly visual, multi-platform skeleton of the Synapse 3D Editor that correctly demonstrates synchronous Dart-Rust FFI communication and Riverpod-managed responsive UI rendering.

## Key Deliverables
1. **Cross-Platform Skeleton**: A Flutter project configured for Web, macOS, Windows, and Linux.
2. **Rust Integration**: A Bevy-powered Rust library package compiled as `cdylib`/`staticlib` with Cargo.
3. **Synchronous FFI channel**: A `greet` function mapped via `flutter_rust_bridge` that communicates at sub-microsecond speed.
4. **State Management**: A Riverpod State Notifier compiled via `build_runner` code generation.
5. **Interactive Dashboard UI**: A 3D Viewport displaying a rotating diorama with interactive left Sidebar (Scene tree) and right Sidebar (Property inspector) showing instant state-synchronized slider updates.
