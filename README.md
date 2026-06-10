# Synapse 3D Editor 🚀

Synapse 3D Editor is a professional-grade, cross-platform 3D scene and sandtable design application. It empowers creators and developers with a powerful, fast, and secure workspace by housing a high-performance **2D layout and panel UI** built in **Flutter** alongside a fully concurrent, bare-metal **3D physics and rendering engine** built in **Rust (Bevy 3D)**.

---

## 🌟 Key Features

- **Interactive 3D Viewport**: Real-time rendering of 3D sandtable scenes (floor, slate walls, smart hubs, lamp posts, emissive light bulbs, and 3D chairs) powered by Bevy.
- **Sophisticated 2D Dashboard**: Built with Flutter, featuring a real-time Scene Tree hierarchy, Property Inspector with smooth sliders, and active console logs.
- **Sub-Microsecond Zero-Copy FFI**: Direct, synchronous FFI communications between Dart and Rust utilizing `flutter_rust_bridge` v2, preventing lag and memory overhead.
- **Slick State Management**: Driven by Riverpod v2 with compile-time code generation for selective leaf widget updates and premium CPU efficiency.
- **Multi-Platform Native Speed**: Compiles natively to Web (WebAssembly/WebGL2/WebGPU), macOS, Windows, and Linux desktops with 100% hardware acceleration.

---

## 🛠️ Technology Stack

| Layer | Technology | Role |
| :--- | :--- | :--- |
| **Frontend UI** | [Flutter](https://flutter.dev/) (Dart) | Modern 2D control panels, layout, and UI state management |
| **3D Engine** | [Bevy Engine](https://bevyengine.org/) (Rust) | Fully concurrent, ECS-based 3D renderer and physics |
| **FFI Bridge** | [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) v2 | Low-latency, zero-copy synchronous FFI compilation |
| **State Management**| [Riverpod v2](https://riverpod.dev/) | Compile-time code-generated UI state binding |

---

## 📂 Project Structure

```text
synapse/
├── lib/                     # Flutter Dart codebase
│   ├── main.dart            # Main App entrance and Dashboard UI
│   ├── state/               # Riverpod State Management & generated providers
│   └── src/rust/            # Auto-generated Dart FFI bindings for Rust
├── rust/                    # Rust backend crate
│   ├── src/api/             # Rust public FFI API (e.g. simple.rs)
│   ├── src/lib.rs           # Crate entry point
│   └── Cargo.toml           # Rust package configuration
├── conductor/               # Conductor workflow specs & roadmap tracker
└── LICENSE                  # MIT Open-Source License
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- **Flutter SDK** (Channel Stable, >= 3.12)
- **Rust Toolchain** (via [rustup](https://rustup.rs/))
- **flutter_rust_bridge_codegen** compiler:
  ```bash
  cargo install flutter_rust_bridge_codegen --version 2.12.0
  ```

### Quick Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/synapse.git
   cd synapse
   ```

2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate FFI Bindings**:
   Run the code generator to bridge Dart and Rust:
   ```bash
   flutter_rust_bridge_codegen generate
   ```

4. **Run Code Generation** (Riverpod Providers):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the Application**:
   Select your preferred target platform and run:
   ```bash
   flutter run -d macos    # On macOS
   # OR
   flutter run -d windows  # On Windows
   # OR
   flutter run -d chrome   # Web platform
   ```

---

## 📜 License & Attribution

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

### How It Works:
- **Free for Noncommercial Purposes**: You are granted a personal, worldwide, royalty-free, and non-exclusive license to view, use, copy, modify, and distribute the Software for non-commercial purposes (personal, educational, research, or hobby use).
- **Commercial Use Requires a Paid License**: Any use of the Software primarily intended for or directed toward commercial advantage or monetary compensation is excluded from this license and **requires a separate, paid Commercial License** from the Licensor (Hogan).

For commercial licensing inquiries, please contact the author directly. See the full [LICENSE](./LICENSE) file for terms and conditions.
