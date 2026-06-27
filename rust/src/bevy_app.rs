use bevy::prelude::*;
use bevy::render::camera::RenderTarget;
use bevy::render::render_resource::{
    Extent3d, TextureDescriptor, TextureDimension, TextureFormat, TextureUsages,
};
use std::sync::{Mutex, OnceLock};

// Raw Send/Sync newtype wrapper for the Bevy App
pub struct SendApp(pub App);
unsafe impl Send for SendApp {}
unsafe impl Sync for SendApp {}

pub static BEVY_APP: OnceLock<Mutex<SendApp>> = OnceLock::new();

#[derive(Resource)]
pub struct OffscreenViewport {
    pub image_handle: Handle<Image>,
    pub width: u32,
    pub height: u32,
}

pub fn start_bevy_app() {
    if BEVY_APP.get().is_some() {
        return; // Already initialized
    }

    let mut app = App::new();

    // 1. Add DefaultPlugins with an Invisible 1x1 Primary Window.
    // This allows Bevy to natively and flawlessly initialize all of its GPU rendering resources,
    // input systems, and GpuPreprocessing lints without missing-resource panics or thread crashes,
    // while keeping the viewport completely hidden from the user.
    app.add_plugins(DefaultPlugins.set(WindowPlugin {
        primary_window: Some(Window {
            title: "Synapse Bevy Headless Engine".to_string(),
            resolution: (1.0, 1.0).into(), // 1x1 pixel
            visible: false,                // Completely invisible!
            ..default()
        }),
        ..default()
    }));

    // We do NOT run Bevy's built-in main loop.
    // Instead, we tick the App manually on-demand from the VSync FFI trigger!

    // 2. Setup our 3D CAD/Digital Twin scene
    app.add_systems(Startup, setup_3d_scene);

    // 3. Run Bevy's startup systems immediately
    app.update();

    BEVY_APP.get_or_init(|| Mutex::new(SendApp(app)));

    info!("[Bevy] Headless 3D CAD Engine successfully initialized and ready for manual FFI ticks.");
}

fn setup_3d_scene(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut images: ResMut<Assets<Image>>,
) {
    let width = 1280;
    let height = 720;

    // Create an offscreen Image asset to act as our active render target
    let size = Extent3d {
        width,
        height,
        ..default()
    };

    let mut image = Image {
        texture_descriptor: TextureDescriptor {
            label: Some("BevyOffscreenRenderTarget"),
            size,
            dimension: TextureDimension::D2,
            format: TextureFormat::Bgra8UnormSrgb, // Perfect match for CVPixelBuffer BGRA8888
            mip_level_count: 1,
            sample_count: 1,
            usage: TextureUsages::RENDER_ATTACHMENT
                | TextureUsages::COPY_SRC
                | TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        },
        ..default()
    };
    image.resize(size);
    let image_handle = images.add(image);

    // Insert viewport handle as a global resource
    commands.insert_resource(OffscreenViewport {
        image_handle: image_handle.clone(),
        width,
        height,
    });

    // Spawn 3D offscreen camera rendering directly to our shared Image asset
    commands.spawn(Camera3dBundle {
        camera: Camera {
            target: RenderTarget::Image(image_handle),
            ..default()
        },
        transform: Transform::from_xyz(3.0, 3.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });

    // Spawn standard CAD directional light source
    commands.spawn(DirectionalLightBundle {
        directional_light: DirectionalLight {
            shadows_enabled: true,
            illuminance: 10000.0,
            ..default()
        },
        transform: Transform::from_xyz(2.0, 5.0, 2.0).looking_at(Vec3::ZERO, Vec3::Y),
        ..default()
    });

    // Spawn Walnut Floor Cuboid
    commands.spawn(PbrBundle {
        mesh: meshes.add(Cuboid::new(10.0, 0.1, 10.0)),
        material: materials.add(Color::from(Srgba::hex("#3E2723").unwrap())),
        transform: Transform::from_xyz(0.0, -0.05, 0.0),
        ..default()
    });

    // Spawn Intelligent PLC Robotic Arm (GLB Mesh mock)
    commands.spawn(PbrBundle {
        mesh: meshes.add(Cuboid::new(1.0, 2.0, 1.0)),
        material: materials.add(Color::from(Srgba::hex("#FFCC00").unwrap())),
        transform: Transform::from_xyz(0.0, 1.0, 0.0),
        ..default()
    });

    info!("[Bevy] Default 3D offscreen scene objects successfully spawned.");
}
