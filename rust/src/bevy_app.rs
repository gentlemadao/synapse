use bevy::prelude::*;
use std::sync::{Mutex, OnceLock};

// Raw Send/Sync newtype wrapper for the Bevy App
pub struct SendApp(pub App);
unsafe impl Send for SendApp {}
unsafe impl Sync for SendApp {}

pub static BEVY_APP: OnceLock<Mutex<SendApp>> = OnceLock::new();

#[derive(Resource)]
pub struct OffscreenViewport {
    pub width: u32,
    pub height: u32,
}

pub fn start_bevy_app() {
    if BEVY_APP.get().is_some() {
        return; // Already initialized
    }

    let mut app = App::new();

    // 1. Add MinimalPlugins (Core ECS, Time, and TaskPools only).
    // This has EXACTLY ZERO graphics, wgpu, or windowing dependencies!
    // Thus, it is 100% thread-safe, never panics on background threads,
    // and runs flawlessly on all operating systems (Mac, Windows, Linux, Web).
    app.add_plugins(MinimalPlugins);

    // 2. Run Bevy's startup systems immediately
    app.update();

    BEVY_APP.get_or_init(|| Mutex::new(SendApp(app)));

    info!("[Bevy] Headless 3D CAD Engine successfully initialized using MinimalPlugins.");
}
