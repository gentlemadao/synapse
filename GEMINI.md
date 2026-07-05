# Synapse Project Instructions & Codified Rules

This document codifies the foundational team-shared workflows, quality gates, and code-styling mandates for the Synapse Collaborative 3D Design Platform repository.

---

## 🚨 Foundational Mandate: Strict Pre-Commit Verification

Every contributor (human developer or AI agent) **MUST** run and pass the entire local verification suite before performing any commit or pushing code changes to GitHub.

---

## 🛠️ Mandatory Local CI Quality Gates

Before committing, you must run these exact verification suites sequentially. **Any warning or error is considered a compilation failure** and must be resolved before proceeding.

### 1. Flutter / Dart Quality Gates
All Dart code must pass standard linter and testing gates:
- **Style Formatting**: Run `dart format --output=none --set-exit-if-changed lib/ test/`. Must return `0` unformatted files.
- **Static Analysis**: Run `flutter analyze`. Must return `"No issues found!"` with exactly zero warnings or errors.
- **Automated Tests**: Run `flutter test`. All unit and widget tests must pass 100%.

### 2. Rust Backend Quality Gates
All Rust code must pass the strictest compiler and lints check:
- **Style Formatting**: Run `cargo fmt -- --check`. Must return `0` formatting differences.
- **Strict Clippy Linter**: Run `cargo clippy --all-targets --all-features -- -D warnings`. **Every warning is treated as an error (`-D warnings`) and must be resolved.**
- **Automated Tests**: Run `cargo test --all-features`. All unit and integration tests must pass 100%.

---

## 📐 Graphic Interop & Multi-Platform Standards

- **No Warning Suppression Hacks**: Bypassing, silencing, or suppressing compiler lints/warnings (e.g. using `#[allow(...)]` or disabling lints) is strictly forbidden unless explicitly requested. Always write standard-compliant, safe, and idiomatic code instead.
- **Direct C-FFI direct symbol bindings**: When bridging native swift or C++ with Rust, prefer direct C-ABI symbols using Swift `@_silgen_name` and Rust `#[unsafe(no_mangle)]` to bypass complex bridging headers.
- **Memory-safe Pointer Dereferencing**: Any FFI function dereferencing raw pointers must be marked `pub unsafe extern "C" fn` and must contain a markdown `# Safety` documentation block describing its safety requirements.
- **Responsive Layout Safeguards**: All 2D UI panels must provide responsive widths, flexible spacing, and text overflow ellipsis to prevent layout overflows under tight desktop constraints.
