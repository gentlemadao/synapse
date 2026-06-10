# Product Guidelines: Synapse Collaborative 3D Design Platform

## User Experience (UX) & Design Language
1. **High Visual Impact & Polish**: The editor must feel alive, professional, and tactile. Spacing, typography, and dark-themed contrasts must remain consistent, with clear active-state indicators and smooth animations.
2. **Instant Multi-User Feedback**: All changes made by any collaborator (e.g., transform drags, albedo changes) must replicate instantly in the 3D viewports of all other connected clients with fluid motion interpolation.
3. **Responsive UI & Workspace**: The layout must adapt gracefully to different screen widths. Sidebars and panels must support drag-resizing, while menus must collapse into horizontal scrolls to prevent overflow on narrow screens.
4. **Graceful Degraded Fallbacks**: In environments lacking WebGPU or hardware acceleration, the application must catch exceptions gracefully, presenting a fully functional 2D canvas and project manager dashboard rather than crashing.

## Architecture Constraints
1. **Zero-Copy FFI Boundary**: Large 3D geometries, texture files, and scene data must remain on the Rust heap inside `RustOpaque` pointers. Only minimal transform and state updates can cross the Dart-Rust boundary per frame.
2. **Selective UI Rebuilds**: The Flutter widget tree must utilize Riverpod providers to rebuild only the affected leaf widgets (e.g., coordinates label, slider value) during drag interactions, keeping the rest of the UI (such as the Scene Tree or Terminal logs) static.
3. **Synchronous Control Flow**: Critical interactive events (mouse drags, parameter updates) must use synchronous FFI bindings (`#[frb(sync)]`) to guarantee zero-latency input mapping.
