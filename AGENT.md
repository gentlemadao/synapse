# Synapse Developer & AI Agent Guidelines 🤖

This document defines critical quality gates and mandatory rules that all developers and AI agents must adhere to when contributing to the Synapse 3D Editor repository.

---

## 🚨 Core Mandate: Pre-Commit CI Validation

**Every contributor (human or AI agent) MUST ensure that all local CI verification checks pass 100% cleanly BEFORE making any commit or submitting a Pull Request.**

Never assume success; compile, lint, and test your changes empirically.

---

## 🛠️ Local CI Verification Suite

Before committing, run the following verification commands sequentially in your local environment. If any check fails, resolve the issue and re-run the validation suite.

### 1. Flutter / Dart Quality Gates

Run these commands in the project root directory:

```bash
# Verify formatting (must return 0 changed/unformatted files)
dart format --output=none --set-exit-if-changed lib/ test/

# Verify static analysis (must return "No issues found!")
flutter analyze

# Run Flutter Unit & Widget tests (must pass 100%)
flutter test
```

### 2. Rust Backend Quality Gates

Run these commands in the `rust/` directory:

```bash
# Verify Rust formatting (must return 0 differences)
cargo fmt -- --check

# Verify Rust static analysis and safety (must return zero errors/warnings)
cargo clippy -- -D warnings

# Run Rust unit and integration tests (must pass 100%)
cargo test
```

---

## 📐 Responsive Layout & Testing Standards

- **Widescreen Viewport**: Widget tests in `test/` are configured to run at a widescreen desktop resolution of `1920x1080` to simulate the production application environment accurately.
- **Responsive Widths**: When designing 2D panel layouts, always wrap flexible text, columns, or rows in `Flexible` or `Expanded` widgets. Always provide graceful clipping (e.g. `TextOverflow.ellipsis`) for labels inside fixed-width containers (such as the 280px left sidebar and 320px right sidebar) to prevent layout overflows under tight constraints or alternative rendering fonts.
- **Zero Memory Leaks**: Always assign long-running timers or streams (such as physics loops or log polls) to instance fields and cancel them explicitly in the widget's `dispose()` method.
