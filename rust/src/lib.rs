#![allow(unexpected_cfgs)]

pub mod api;
pub mod bevy_app;

#[allow(clippy::all)]
#[allow(unused_imports)]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub mod frb_generated;

use std::collections::HashMap;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::sync::{Mutex, OnceLock};

static VIEWPORTS: OnceLock<Mutex<HashMap<u64, ViewportState>>> = OnceLock::new();
static SCENE_NODES: OnceLock<Mutex<Vec<SceneNode>>> = OnceLock::new();
static CURRENT_ANGLES: OnceLock<Mutex<(f64, f64)>> = OnceLock::new();

pub struct ViewportState {
    pub viewport_id: u64,
    pub width: u32,
    pub height: u32,
    pub rotation: f64,
}

#[derive(serde::Serialize, serde::Deserialize, Clone, Debug)]
pub struct SceneNode {
    pub id: String,
    pub name: String,
    pub r#type: String, // matches Dart type
    pub px: f64,
    pub py: f64,
    pub pz: f64,
    pub scale: f64,
    pub color: String,
    pub visible: bool,
}

fn get_viewports() -> &'static Mutex<HashMap<u64, ViewportState>> {
    VIEWPORTS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_scene_nodes() -> &'static Mutex<Vec<SceneNode>> {
    SCENE_NODES.get_or_init(|| Mutex::new(Vec::new()))
}

fn get_current_angles() -> &'static Mutex<(f64, f64)> {
    CURRENT_ANGLES.get_or_init(|| Mutex::new((0.5, 0.3)))
}

#[unsafe(no_mangle)]
pub extern "C" fn synapse_bevy_init_viewport(viewport_id: u64, width: u32, height: u32) -> u64 {
    let mut viewports = get_viewports().lock().unwrap();

    let state = ViewportState {
        viewport_id,
        width,
        height,
        rotation: 0.0,
    };

    let is_first = viewports.is_empty();
    viewports.insert(viewport_id, state);
    eprintln!(
        "[Rust FFI] Initialized viewport with Handle: {}, size: {}x{}",
        viewport_id, width, height
    );

    if is_first {
        bevy_app::start_bevy_app();
    }

    viewport_id
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

/// Updates the active scene nodes list in Rust by parsing a JSON-serialized string of nodes.
///
/// # Safety
///
/// This function is unsafe because it dereferences the raw C-string pointer `json_ptr`.
/// The caller must ensure that `json_ptr` is a valid, null-terminated UTF-8 C-string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn synapse_bevy_update_nodes(json_ptr: *const c_char) {
    if json_ptr.is_null() {
        return;
    }
    let c_str = unsafe { CStr::from_ptr(json_ptr) };
    let nodes_opt = c_str
        .to_str()
        .ok()
        .and_then(|json_str| serde_json::from_str::<Vec<SceneNode>>(json_str).ok());
    if let Some(nodes) = nodes_opt {
        let mut scene_nodes = get_scene_nodes().lock().unwrap();
        *scene_nodes = nodes;
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn synapse_bevy_update_angles(h_angle: f64, v_angle: f64) {
    let mut angles = get_current_angles().lock().unwrap();
    *angles = (h_angle, v_angle);
}

// ==========================================================
// 3D Perspective Software Wireframe Rasterizer (Pro-Grade)
// ==========================================================

// ScreenBuffer wraps our output memory buffer properties to satisfy Clippy's argument count rules
pub struct ScreenBuffer {
    pub width: u32,
    pub height: u32,
    pub pixels: *mut u8,
}

// Standard Bresenham's integer line-drawing algorithm
fn draw_line(x0: i32, y0: i32, x1: i32, y1: i32, color: [u8; 4], screen: &ScreenBuffer) {
    let dx = (x1 - x0).abs();
    let dy = (y1 - y0).abs();
    let sx = if x0 < x1 { 1 } else { -1 };
    let sy = if y0 < y1 { 1 } else { -1 };
    let mut err = dx - dy;

    let mut x = x0;
    let mut y = y0;

    loop {
        if x >= 0 && x < screen.width as i32 && y >= 0 && y < screen.height as i32 {
            let offset = ((y * screen.width as i32 + x) * 4) as isize;
            unsafe {
                // out_pixels is in BGRA8888 memory format
                *screen.pixels.offset(offset) = color[0]; // B
                *screen.pixels.offset(offset + 1) = color[1]; // G
                *screen.pixels.offset(offset + 2) = color[2]; // R
                *screen.pixels.offset(offset + 3) = 255; // A
            }
        }

        if x == x1 && y == y1 {
            break;
        }

        let e2 = 2 * err;
        if e2 > -dy {
            err -= dy;
            x += sx;
        }
        if e2 < dx {
            err += dx;
            y += sy;
        }
    }
}

// Projects 3D wireframe cube corners into 2D perspective screen space
fn draw_wireframe_cube(
    center: [f64; 3],
    size: [f64; 3],
    color: [u8; 4],
    h_angle: f64,
    v_angle: f64,
    screen: &ScreenBuffer,
) {
    let half_x = size[0] / 2.0;
    let half_y = size[1] / 2.0;
    let half_z = size[2] / 2.0;

    let vertices = [
        [center[0] - half_x, center[1] - half_y, center[2] - half_z],
        [center[0] + half_x, center[1] - half_y, center[2] - half_z],
        [center[0] + half_x, center[1] + half_y, center[2] - half_z],
        [center[0] - half_x, center[1] + half_y, center[2] - half_z],
        [center[0] - half_x, center[1] - half_y, center[2] + half_z],
        [center[0] + half_x, center[1] - half_y, center[2] + half_z],
        [center[0] + half_x, center[1] + half_y, center[2] + half_z],
        [center[0] - half_x, center[1] + half_y, center[2] + half_z],
    ];

    let mut projected = [[0, 0]; 8];
    for (i, v) in vertices.iter().enumerate() {
        let cos_h = h_angle.cos();
        let sin_h = h_angle.sin();
        let cos_v = v_angle.cos();
        let sin_v = v_angle.sin();

        // 1. Rotate around Y-axis (yaw)
        let rx1 = v[0] * cos_h - v[2] * sin_h;
        let rz1 = v[0] * sin_h + v[2] * cos_h; // Standard 3D rigid rotation

        // 2. Rotate around X-axis (pitch)
        let ry2 = v[1] * cos_v - rz1 * sin_v;
        let rz2 = v[1] * sin_v + rz1 * cos_v;

        // 3. Perspective Projection
        let dist = 4.0;
        let perspective = dist / (dist + rz2);

        let cx = screen.width as f64 / 2.0;
        let cy = screen.height as f64 / 2.0;
        let scale_factor = (screen.width.min(screen.height) as f64) * 0.15;

        let sx = cx + rx1 * scale_factor * perspective;
        let sy = cy - ry2 * scale_factor * perspective;
        projected[i] = [sx as i32, sy as i32];
    }

    let edges = [
        (0, 1),
        (1, 2),
        (2, 3),
        (3, 0), // Bottom face
        (4, 5),
        (5, 6),
        (6, 7),
        (7, 4), // Top face
        (0, 4),
        (1, 5),
        (2, 6),
        (3, 7), // Vertical pillars
    ];

    for &(start, end) in &edges {
        draw_line(
            projected[start][0],
            projected[start][1],
            projected[end][0],
            projected[end][1],
            color,
            screen,
        );
    }
}

// Projects 3D wireframe cylinder (8 segments) into 2D perspective screen space
fn draw_wireframe_cylinder(
    center: [f64; 3],
    radius: f64,
    height_size: f64,
    color: [u8; 4],
    h_angle: f64,
    v_angle: f64,
    screen: &ScreenBuffer,
) {
    let half_h = height_size / 2.0;
    let segments = 8;
    let mut top_projected = [[0, 0]; 8];
    let mut bot_projected = [[0, 0]; 8];

    for i in 0..segments {
        let angle = (i as f64) * 2.0 * std::f64::consts::PI / (segments as f64);
        let dx = radius * angle.cos();
        let dz = radius * angle.sin();

        let top_v = [center[0] + dx, center[1] + half_h, center[2] + dz];
        let bot_v = [center[0] + dx, center[1] - half_h, center[2] + dz];

        let cos_h = h_angle.cos();
        let sin_h = h_angle.sin();
        let cos_v = v_angle.cos();
        let sin_v = v_angle.sin();

        // Project top vertex
        let rx1 = top_v[0] * cos_h - top_v[2] * sin_h;
        let rz_temp1 = top_v[0] * sin_h + top_v[2] * cos_h;
        let ry1 = top_v[1] * cos_v - rz_temp1 * sin_v;
        let rz2_1 = top_v[1] * sin_v + rz_temp1 * cos_v;

        let dist = 4.0;
        let perspective1 = dist / (dist + rz2_1);
        let cx = screen.width as f64 / 2.0;
        let cy = screen.height as f64 / 2.0;
        let scale_factor = (screen.width.min(screen.height) as f64) * 0.15;

        let sx1 = cx + rx1 * scale_factor * perspective1;
        let sy1 = cy - ry1 * scale_factor * perspective1;
        top_projected[i] = [sx1 as i32, sy1 as i32];

        // Project bottom vertex
        let rx2 = bot_v[0] * cos_h - bot_v[2] * sin_h;
        let rz_temp2 = bot_v[0] * sin_h + bot_v[2] * cos_h;
        let ry2 = bot_v[1] * cos_v - rz_temp2 * sin_v;
        let rz2_2 = bot_v[1] * sin_v + rz_temp2 * cos_v;

        let perspective2 = dist / (dist + rz2_2);
        let sx2 = cx + rx2 * scale_factor * perspective2;
        let sy2 = cy - ry2 * scale_factor * perspective2;
        bot_projected[i] = [sx2 as i32, sy2 as i32];
    }

    // Connect top and bottom circular faces & vertical side bars
    for i in 0..segments {
        let next = (i + 1) % segments;
        // Top circle edge
        draw_line(
            top_projected[i][0],
            top_projected[i][1],
            top_projected[next][0],
            top_projected[next][1],
            color,
            screen,
        );
        // Bottom circle edge
        draw_line(
            bot_projected[i][0],
            bot_projected[i][1],
            bot_projected[next][0],
            bot_projected[next][1],
            color,
            screen,
        );
        // Vertical side pillar
        draw_line(
            top_projected[i][0],
            top_projected[i][1],
            bot_projected[i][0],
            bot_projected[i][1],
            color,
            screen,
        );
    }
}

// Helper to parse Hex color strings (e.g. #FFCC00) into BGRA [u8; 4] format
fn parse_hex_color(hex: &str) -> [u8; 4] {
    let cleaned = hex.trim_start_matches('#');
    if cleaned.len() == 6 {
        let r = u8::from_str_radix(&cleaned[0..2], 16).unwrap_or(255);
        let g = u8::from_str_radix(&cleaned[2..4], 16).unwrap_or(255);
        let b = u8::from_str_radix(&cleaned[4..6], 16).unwrap_or(255);
        [b, g, r, 255] // BGRA order
    } else {
        [255, 255, 255, 255]
    }
}

/// Renders a single 3D wireframe frame and copies the pixel data into the output buffer.
///
/// # Safety
///
/// This function is unsafe because it dereferences the raw pointer `out_pixels`.
/// The caller must ensure that `out_pixels` points to a valid, writable block of memory
/// of at least `width * height * 4` bytes.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn synapse_bevy_render_frame(viewport_id: u64, out_pixels: *mut u8) {
    if out_pixels.is_null() {
        return;
    }

    // 1. Get viewport size and animation angle
    let (width, height);
    {
        let viewports = get_viewports().lock().unwrap();
        if let Some(state) = viewports.get(&viewport_id) {
            width = state.width;
            height = state.height;
        } else {
            return;
        }
    }

    if width == 0 || height == 0 {
        return;
    }

    // Get current horizontal and vertical orbit angles from global state (populated dynamically by Flutter!)
    let h_angle;
    let v_angle;
    {
        let angles = get_current_angles().lock().unwrap();
        h_angle = angles.0;
        v_angle = angles.1;
    }

    // Wrap viewport context in our Clippy-friendly struct
    let screen = ScreenBuffer {
        width,
        height,
        pixels: out_pixels,
    };

    // 2. Clear background to gorgeous dark space-theme `#090A0F`
    let bg_color = [15, 10, 9, 255]; // BGRA
    unsafe {
        let total_bytes = (width * height * 4) as usize;
        let mut offset = 0;
        while offset < total_bytes {
            std::ptr::copy_nonoverlapping(bg_color.as_ptr(), out_pixels.add(offset), 4);
            offset += 4;
        }
    }

    // 3. Draw 3D floor CAD grid lines synchronously
    let grid_color = [50, 41, 30, 255]; // BGRA (Matte Slate Grey)
    let grid_size = 5;
    for g in -grid_size..=grid_size {
        // Horizontal lines along X-axis
        let start_pos = [g as f64, -0.84, -grid_size as f64];
        let end_pos = [g as f64, -0.84, grid_size as f64];
        draw_3d_line_helper(start_pos, end_pos, grid_color, h_angle, v_angle, &screen);

        // Vertical lines along Z-axis
        let start_pos_z = [-grid_size as f64, -0.84, g as f64];
        let end_pos_z = [grid_size as f64, -0.84, g as f64];
        draw_3d_line_helper(
            start_pos_z,
            end_pos_z,
            grid_color,
            h_angle,
            v_angle,
            &screen,
        );
    }

    // 4. Render our 3D CAD/Digital Twin scene geometries dynamically
    let scene_nodes = get_scene_nodes().lock().unwrap();
    if scene_nodes.is_empty() {
        // Fallback: draw our default wireframe scene if no nodes are synced yet
        draw_wireframe_cube(
            [0.0, -0.84, 0.0],
            [6.0, 0.1, 6.0],
            [35, 39, 62, 255],
            h_angle,
            v_angle,
            &screen,
        );
        draw_wireframe_cube(
            [0.5, -0.77, 0.5],
            [1.5, 0.15, 1.0],
            [81, 65, 55, 255],
            h_angle,
            v_angle,
            &screen,
        );
        draw_wireframe_cube(
            [0.5, -0.64, 0.5],
            [0.3, 0.3, 0.3],
            [255, 255, 0, 255],
            h_angle,
            v_angle,
            &screen,
        );
        draw_wireframe_cylinder(
            [-1.1, -0.09, -1.1],
            0.08,
            1.5,
            [235, 231, 229, 255],
            h_angle,
            v_angle,
            &screen,
        );
        draw_wireframe_cube(
            [0.0, 0.0, 0.0],
            [0.8, 1.6, 0.8],
            [0, 204, 255, 255],
            h_angle,
            v_angle,
            &screen,
        );
        draw_wireframe_cylinder(
            [-1.1, 0.66, -1.1],
            0.3,
            0.3,
            [169, 209, 255, 255],
            h_angle,
            v_angle,
            &screen,
        );
    } else {
        // Draw the dynamic, synchronized scene nodes in real-time!
        for node in scene_nodes.iter() {
            if !node.visible {
                continue;
            }

            // Parse Hex color string (e.g. #FFCC00) into BGRA [u8; 4]
            let color = parse_hex_color(&node.color);
            let center = [node.px, node.py, node.pz];
            let size_factor = node.scale;

            match node.r#type.as_str() {
                "Cuboid" => {
                    // Walnut Floor, Coffee Table, or walls
                    let size = if node.id == "node_0" {
                        [6.0 * size_factor, 0.1 * size_factor, 6.0 * size_factor]
                    } else if node.id == "node_3" {
                        [1.5 * size_factor, 0.15 * size_factor, 1.0 * size_factor]
                    } else if node.id == "node_4" {
                        [0.3 * size_factor, 0.3 * size_factor, 0.3 * size_factor]
                    } else {
                        [0.8 * size_factor, 1.6 * size_factor, 0.8 * size_factor]
                    };
                    draw_wireframe_cube(center, size, color, h_angle, v_angle, &screen);
                }
                "Cylinder" => {
                    // Lamp post
                    draw_wireframe_cylinder(
                        center,
                        0.08 * size_factor,
                        1.5 * size_factor,
                        color,
                        h_angle,
                        v_angle,
                        &screen,
                    );
                }
                "Sphere" => {
                    // Smart Glow Bulb or AI globe
                    draw_wireframe_cylinder(
                        center,
                        0.3 * size_factor,
                        0.3 * size_factor,
                        color,
                        h_angle,
                        v_angle,
                        &screen,
                    );
                }
                _ => {
                    // Default GLB meshes (e.g. robotic arm chair)
                    draw_wireframe_cube(
                        center,
                        [0.8 * size_factor, 1.6 * size_factor, 0.8 * size_factor],
                        color,
                        h_angle,
                        v_angle,
                        &screen,
                    );
                }
            }
        }
    }

    // 5. Still tick the background Bevy App to keep ECS/CRDT schedules active in sync!
    if let Some(app_mutex) = bevy_app::BEVY_APP.get() {
        let mut app_wrapper = match app_mutex.lock() {
            Ok(guard) => guard,
            Err(_) => return,
        };
        app_wrapper.0.update();
    }
}

// 3D-to-2D Line Drawing helper
fn draw_3d_line_helper(
    start: [f64; 3],
    end: [f64; 3],
    color: [u8; 4],
    h_angle: f64,
    v_angle: f64,
    screen: &ScreenBuffer,
) {
    let cos_h = h_angle.cos();
    let sin_h = h_angle.sin();
    let cos_v = v_angle.cos();
    let sin_v = v_angle.sin();

    // Project start point
    let rx1 = start[0] * cos_h - start[2] * sin_h;
    let rz_temp1 = start[0] * sin_h + start[2] * cos_h;
    let ry1 = start[1] * cos_v - rz_temp1 * sin_v;
    let rz2_1 = start[1] * sin_v + rz_temp1 * cos_v;

    let dist = 4.0;
    let perspective1 = dist / (dist + rz2_1);
    let cx = screen.width as f64 / 2.0;
    let cy = screen.height as f64 / 2.0;
    let scale_factor = (screen.width.min(screen.height) as f64) * 0.15;

    let sx1 = cx + rx1 * scale_factor * perspective1;
    let sy1 = cy - ry1 * scale_factor * perspective1;

    // Project end point
    let rx2 = end[0] * cos_h - end[2] * sin_h;
    let rz_temp2 = end[0] * sin_h + end[2] * cos_h;
    let ry2 = end[1] * cos_v - rz_temp2 * sin_v;
    let rz2_2 = end[1] * sin_v + rz_temp2 * cos_v;

    let perspective2 = dist / (dist + rz2_2);
    let sx2 = cx + rx2 * scale_factor * perspective2;
    let sy2 = cy - ry2 * scale_factor * perspective2;

    if rz2_1 + dist > 0.1 && rz2_2 + dist > 0.1 {
        draw_line(
            sx1 as i32, sy1 as i32, sx2 as i32, sy2 as i32, color, screen,
        );
    }
}
