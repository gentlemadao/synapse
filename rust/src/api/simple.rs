#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}! Greetings from Synapse 3D (Rust + Bevy 0.14)!")
}

thread_local! {
    static DUMMY_TLS: std::cell::Cell<u32> = const { std::cell::Cell::new(0) };
}

#[unsafe(no_mangle)]
pub extern "C" fn force_tls_generation() -> u32 {
    DUMMY_TLS.with(|cell| cell.get())
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_viewport_wasm(viewport_id: u64, width: u32, height: u32) {
    crate::synapse_bevy_init_viewport(viewport_id, width, height);
}

#[flutter_rust_bridge::frb(sync)]
pub fn resize_viewport_wasm(viewport_id: u64, width: u32, height: u32) {
    crate::synapse_bevy_resize_viewport(viewport_id, width, height);
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_nodes_wasm(nodes_json: String) {
    if let Ok(c_str) = std::ffi::CString::new(nodes_json) {
        unsafe {
            crate::synapse_bevy_update_nodes(c_str.as_ptr());
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_angles_wasm(h_angle: f64, v_angle: f64) {
    crate::synapse_bevy_update_angles(h_angle, v_angle);
}

#[flutter_rust_bridge::frb(sync)]
pub fn render_frame_wasm(viewport_id: u64, width: u32, height: u32) -> Vec<u8> {
    let mut buffer = vec![0u8; (width * height * 4) as usize];
    unsafe {
        crate::synapse_bevy_render_frame(viewport_id, buffer.as_mut_ptr());
    }
    buffer
}
