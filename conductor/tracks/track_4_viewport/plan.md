# Track 4 Implementation Plan: Bevy Cross-Platform GPU Viewport & Texture Sharing

## 1. Background & Motivation
Currently, the Synapse 3D Editor uses a custom CPU-based 3D projection on a Flutter `CustomPainter` to mock 3D rendering. To transition the application into a heavy industrial-grade digital twin platform, we must integrate a real, hardware-accelerated 3D viewport.

This track implements a zero-copy, hardware-accelerated 3D viewport by embedding a headless **Bevy 0.14** engine into the Flutter window across **all supported target platforms (macOS, Windows, Linux, and Web Browser)** using native GPU texture sharing registries and dual-canvas overlays.

---

## 2. Scope & Impact
- **Scope**:
  - Native `FlutterTexture` hosts on macOS (Metal/IOSurface), Windows (DirectX/DXGI), and Linux (OpenGL/dmabuf).
  - Web Browser dual-canvas alignment, transparent Flutter view rendering, and resize listeners.
  - Core headless Bevy 0.14 integrations and wgpu context wrapping across all target platforms.
  - Unified Dart Riverpod viewport state managing multi-platform initialization.
- **Impact**:
  - Sub-millisecond rendering latency (120Hz smooth compositor rendering) on all desktops.
  - Zero CPU copying overhead across all native target operating systems.
  - Native browser WebGL2/WebGPU performance on the Web.

---

## 3. Proposed Solutions by Platform

### 3.1 macOS: Metal + IOSurface (Zero-Copy)
1. **Swift** allocates an `IOSurface` with Metal-compatible attributes.
2. **Swift** wraps the surface inside a `CVPixelBuffer` and registers it in `FlutterTextureRegistry`, spawning `textureId`.
3. **Rust (wgpu)** wraps the `IOSurface` handle as a `wgpu::Texture` using HAL Metal bindings.
4. **Rust (Bevy)** renders offscreen directly into this shared texture.

### 3.2 Windows: DirectX 11/12 + DXGI Shared Handle
1. **C++ (Runner)** allocates a shared 2D texture (`ID3D11Texture2D`) and retrieves its DXGI Shared Handle.
2. **C++ (Runner)** registers the shared texture with the `FlutterDesktopTextureRegistrar`.
3. **Rust (wgpu)** wraps the DXGI handle as a `wgpu::Texture` using HAL DirectX bindings.
4. **Rust (Bevy)** renders offscreen directly into this shared texture.

### 3.3 Linux: OpenGL / Vulkan + EGL/dmabuf
1. **C++ (Runner)** allocates a dmabuf or EGL Image backing an OpenGL Texture.
2. **C++ (Runner)** registers the GL Texture ID with the Linux `FlutterDesktopTextureRegistrar`.
3. **Rust (wgpu)** wraps the dmabuf handle as a `wgpu::Texture` using Vulkan/OpenGL bindings.
4. **Rust (Bevy)** renders offscreen directly into this shared texture.

### 3.4 Web Browser: Transparent Dual-Canvas Overlay
1. **Dart** spawns a background `<canvas>` behind the transparent Flutter Web canvas using standard HTML layer ordering (`z-index`).
2. **Rust (Bevy WASM)** binds directly to this underlying canvas via WebGL2/WebGPU.
3. **Dart** monitors resize events via `ResizeObserver` and automatically synchronizes width/height parameters of the underlying canvas.

---

## 4. Phased Implementation Plan

### Phase 1: macOS Swift Texture & Channel Setup
- [x] Create a Swift native class `BevyTexture` implementing `FlutterTexture` on macOS.
- [x] Implement `initTexture(width, height)` allocating a Metal-compatible `IOSurface` and `CVPixelBuffer`.
- [x] Expose MethodChannel `synapse/viewport` in `MainFlutterWindow.swift` to handle communication on macOS.

### Phase 2: Windows & Linux Native Texture Registry Setup
- [ ] Implement C++ Direct3D 11 shared texture allocation and DXGI handle extraction on Windows.
- [ ] Integrate Windows `FlutterDesktopTextureRegistrar` to register and update the shared handle.
- [ ] Implement Linux dmabuf/EGL shared OpenGL texture allocations.

### Phase 3: Web Browser Dual-Canvas Overlay Setup
- [ ] Configure Flutter Web index.html and transparent scaffold backgrounds.
- [ ] Implement Dart-side canvas overlay injection, ordering Bevy's target canvas underneath the Flutter canvas.
- [ ] Build Dart `ResizeObserver` script to sync dimensions between Flutter Web viewports and the Bevy Wasm canvas.

### Phase 4: Headless Bevy & wgpu Multi-Backend Context Sharing
- [ ] Configure `rust_lib_synapse` to run Bevy 0.14 without winit plugins (`WinitPlugin` disabled, offscreen mode).
- [ ] Implement Rust platform-specific HAL context wrappers for `IOSurface` (Mac), DXGI (Win), and dmabuf (Linux) using `wgpu::Device::create_texture_from_hal`.
- [ ] Set Bevy's camera `RenderTarget` to the wrapped `wgpu::Texture` across all desktops.

### Phase 5: Frame Synchronization & Multi-Platform Repainting
- [ ] Implement frame-complete FFI callbacks signaling Swift (Mac), C++ (Windows/Linux), and JS (Web).
- [ ] On callback, notify Flutter's texture registry to redraw on desktops.
- [ ] Bind Dart Riverpod state to manage the active `textureId` and inject the `Texture` or `HtmlElementView` widget based on the running platform.

### Phase 6: Verification & Stress Testing
- [ ] Run multi-platform automated tests verifying native texture registrations.
- [ ] Execute rendering under high resolutions (up to 4K) across all environments to measure FPS and resource consumption.

---

## 5. Verification Strategy
- **Automated Tests**:
  - Run `cargo test` and verify compile-check on all systems.
  - Verify that the Web target compiles cleanly via WebAssembly target compilation.
- **Manual Verification**:
  - Run the application on all 4 platforms and check the central workspace. Verify that the 3D scene compiles, renders, and responds to mouse inputs smoothly.

---

## 6. Migration & Rollback Strategies
- **Graceful Fallback**:
  - If native texture registration fails on any platform, catch the exception in Dart and fall back to our existing `SimulatedViewportPainter` (CustomPainter) to prevent app crashes.
- **Rollback**:
  - Reverting this track is as simple as checking out the previous Git commit (`1508ba4`), which safely contains our fully verified 100% clean pre-Track 4 state.
