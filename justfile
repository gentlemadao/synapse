# Justfile - Command runner configuration for Synapse 3D Editor

# List all available commands
default:
    @just --list

# Run the complete pre-commit CI validation suite (Flutter & Rust)
ci: check-flutter check-rust
    @echo "\n✅ [SUCCESS] All local CI checks passed cleanly!"

# Run all Flutter/Dart formatting, analysis, and unit tests
check-flutter:
    @echo "\n=== [1/2] Running Flutter Verification ==="
    @echo "1. Checking Dart formatting..."
    dart format --output=none --set-exit-if-changed lib/ test/
    @echo "2. Running Flutter code analysis..."
    flutter analyze
    @echo "3. Running Flutter tests..."
    flutter test

# Run all Rust formatting, clippy lints, and unit tests
check-rust:
    @echo "\n=== [2/2] Running Rust Verification ==="
    @echo "1. Checking Rust formatting..."
    rustfmt --check rust/src/lib.rs rust/src/api/simple.rs rust/src/api/mod.rs
    @echo "2. Running Rust clippy lints..."
    cargo clippy --manifest-path rust/Cargo.toml -- -D warnings
    @echo "3. Running Rust unit tests..."
    cargo test --manifest-path rust/Cargo.toml
