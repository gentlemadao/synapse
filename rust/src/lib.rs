#![allow(unexpected_cfgs)]

pub mod api;
pub mod bevy_app;

#[allow(clippy::all)]
#[allow(unused_imports)]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub mod frb_generated;

// ==========================================
// C-FFI Bridge for GPU Viewport Sharing
// ==========================================

use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

static VIEWPORTS: OnceLock<Mutex<HashMap<u64, ViewportState>>> = OnceLock::new();

pub struct ViewportState {
    pub iosurface_id: u32,
    pub width: u32,
    pub height: u32,
}

fn get_viewports() -> &'static Mutex<HashMap<u64, ViewportState>> {
    VIEWPORTS.get_or_init(|| Mutex::new(HashMap::new()))
}

#[unsafe(no_mangle)]
pub extern "C" fn synapse_bevy_init_viewport(iosurface_id: u32, width: u32, height: u32) -> u64 {
    let mut viewports = get_viewports().lock().unwrap();
    let id = iosurface_id as u64; // Map IOSurface ID directly as our viewport handler ID

    let state = ViewportState {
        iosurface_id,
        width,
        height,
    };

    let is_first = viewports.is_empty();
    viewports.insert(id, state);
    eprintln!(
        "[Rust FFI] Initialized viewport {} with IOSurface ID: {}, size: {}x{}",
        id, iosurface_id, width, height
    );

    if is_first {
        bevy_app::start_bevy_app();
    }

    id
}

#[unsafe(no_mangle)]
pub extern "C" fn synapse_bevy_resize_viewport(viewport_id: u64, width: u32, height: u32) {
    let mut viewports = get_viewports().lock().unwrap();
    if let Some(state) = viewports.get_mut(&viewport_id) {
        state.width = width;
        state.height = height;
        eprintln!(
            "[Rust FFI] Resized viewport {} to size: {}x{}",
            viewport_id, width, height
        );
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn synapse_bevy_render_frame(_viewport_id: u64, out_pixels: *mut u8) {
    if out_pixels.is_null() {
        return;
    }

    use bevy::prelude::Image;

    if let Some(app_mutex) = bevy_app::BEVY_APP.get() {
        if let Ok(mut app_wrapper) = app_mutex.lock() {
            // 1. Tick Bevy's main loop once! This executes physics, update, and offscreen render ticks.
            app_wrapper.0.update();

            // 2. Extract the offscreen Image asset's raw BGRA8888 pixel bytes
            let image_assets = app_wrapper
                .0
                .world()
                .resource::<bevy::prelude::Assets<Image>>();
            if let Some(viewport) = app_wrapper
                .0
                .world()
                .get_resource::<bevy_app::OffscreenViewport>()
            {
                if let Some(image) = image_assets.get(&viewport.image_handle) {
                    let len = image.data.len();
                    if len > 0 {
                        unsafe {
                            std::ptr::copy_nonoverlapping(image.data.as_ptr(), out_pixels, len);
                        }
                    }
                }
            }
        }
    }
}
