# Tech Stack: Synapse Collaborative 3D Design Platform

This document outlines the deliberate choice of technologies, libraries, and compilation environments for the Synapse project.

## Core Language & Runtimes
- **Frontend App Layer**: Dart & Flutter Framework (Compiled natively for desktop, JS/WASM for web).
- **3D Core & Collaborative Sync**: Rust (v1.96+, Edition 2024).

## 3D Graphics & Simulation
- **Rendering & ECS Engine**: **Bevy 3D Engine** (v0.14) with default-features optimized for native WebGPU/Metal rendering pipelines.
- **Scene Interaction & Picking**: Built-in event-driven `bevy_picking` with Observers.
- **3D Gizmos**: `transform-gizmo-bevy` for translation, rotation, and scaling handles.
- **Camera Controller**: `bevy_editor_cam` for CAD-grade smoothed pan-orbit-zoom camera control.

## Interop & Bridge
- **Rust-to-Dart FFI**: **`flutter_rust_bridge`** (v2.12.0) providing:
  - Synchronous direct C-ABI bindings (`#[frb(sync)]`).
  - Opaque pointers (`RustOpaque`) to secure Rust memory heaps from Dart GC.
  - Multi-platform binding generation for C, Objective-C, and JS/WASM targets.

## State Management & Real-Time Sync
- **State Hub**: **Riverpod** (v2.x) using **Riverpod Generator** for annotation-driven compile-time code-gen, ensuring granular widget rebuilds during high-frequency slider updates.
- **Multiplayer Collaboration Channel**: Low-latency WebSocket connections on top of a conflict-free replicated data type (CRDT) engine (Yjs / Y-Rust) to synchronize scene states across multiple client isolates.

## Supported Target Environments
- **Web Browser**: WebAssembly + WebGL2 / WebGPU (compiled via `flutter build web` & `wasm32-unknown-unknown`).
- **macOS Desktop**: Apple Silicon & Intel native CocoaPods/SPM integration.
- **Windows / Linux**: CMake native compilation.
