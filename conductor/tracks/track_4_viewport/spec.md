# Track 4 Specification: Bevy Cross-Platform GPU Viewport & Texture Sharing

## 1. Multi-Platform Graphics Sharing Architecture

To deliver CAD-grade 3D rendering at 120Hz on all supported platforms (macOS, Windows, Linux, and Web), we implement platform-specific, zero-copy GPU texture sharing pipelines.

```
       ┌────────────────────────────────────────────────────────┐
       │                 Flutter App Canvas Layer               │
       └───────────────────────────┬────────────────────────────┘
                                   │
         ┌─────────────────────────┼─────────────────────────┐
         ▼ (macOS)                 ▼ (Windows)               ▼ (Linux)
   [FlutterTexture]         [D3D11 Shared Texture]     [EGL/OpenGL Texture]
   * IOSurface-backed       * DXGI Shared Handle       * EGLImage/GL TextureID
   * CVPixelBuffer          * D3D11 Resource           * dmabuf / glTexture
         │                         │                         │
         └─────────────────────────┼─────────────────────────┘
                                   ▼
         ┌───────────────────────────────────────────────────┐
         │              Headless Bevy 3D Engine              │
         │  (Offscreen GPU Render to Shared Texture Target)   │
         └───────────────────────────────────────────────────┘
```

For the **Web Browser**, we employ a **Dual-Canvas Layering** strategy:
- Flutter Web renders to a transparent HTML `<canvas>`.
- The Bevy WebAssembly runtime renders directly to a standard WebGL2/WebGPU `<canvas>` positioned precisely underneath Flutter.
- Canvas dimensions and alignments are synchronized reactively in Dart, avoiding any texture copying across the Wasm-JS boundary.

---

## 2. Technical Specifications by Platform

### 2.1 macOS (Metal + IOSurface)
- **Host**: Swift uses `IOSurface` with Metal-compatibility keys.
- **Client**: Rust wraps the `IOSurface` pointer using `wgpu` Metal HAL bindings:
  ```rust
  device.create_texture_from_hal::<wgpu::hal::api::Metal>(...)
  ```
- **Flutter Integration**: `FlutterTexture` protocol returning `CVPixelBufferRef`.

### 2.2 Windows (DirectX 11/12 + DXGI Shared Handles)
- **Host**: C++ uses `ID3D11Device` to allocate a shared 2D texture with `D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX` or `D3D11_RESOURCE_MISC_SHARED`. Get the DXGI shared handle.
- **Client**: Rust wraps the shared handle in `wgpu` using `wgpu::Device::create_texture_from_hal::<wgpu::hal::api::Dx11>` or `Dx12`.
- **Flutter Integration**: Windows `FlutterDesktopTextureRegistrar` registers a texture backed by the shared DXGI texture handle.

### 2.3 Linux (OpenGL / Vulkan + EGL/dmabuf)
- **Host**: C++ creates an EGL Image or dmabuf, registered with the Linux `FlutterDesktopTextureRegistrar` as an OpenGL texture.
- **Client**: Rust wraps the dmabuf / EGL image handle as a `wgpu::Texture` using OpenGL / Vulkan HAL.
- **Flutter Integration**: Flutter's Linux shell directly samples from the shared OpenGL texture ID.

### 2.4 Web Browser (Dual-Canvas Overlay)
- **Alignment**: Standard HTML layer ordering (`z-index`). Flutter Web is ordered on top (`z-index: 2`, transparent background), and the Bevy Wasm canvas is positioned exactly beneath it (`z-index: 1`).
- **Resize Sync**: Standard Dart `ResizeObserver` monitors the Flutter viewport size and updates the underlying HTML canvas width/height attributes dynamically.

---

## 3. Bridge FFI Boundary Prototypes

The cross-platform native bridge boundary exposes the following API:

```rust
#[no_mangle]
pub extern "C" fn synapse_bevy_init_viewport(
    platform_texture_handle: u64, // IOSurfaceID (Mac), DXGI Handle (Win), dmabuf (Linux)
    width: u32,
    height: u32
) -> u64;

#[no_mangle]
pub extern "C" fn synapse_bevy_render_frame(viewport_id: u64);

#[no_mangle]
pub extern "C" fn synapse_bevy_resize_viewport(viewport_id: u64, width: u32, height: u32);
```
