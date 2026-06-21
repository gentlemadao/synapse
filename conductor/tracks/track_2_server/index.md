# Track 2: Collaborative Sync Server

## Overview
This track covers the design, implementation, and verification of a dedicated, high-performance, asynchronous Rust-based collaborative server (`synapse-server`). The server integrates the `yrs` (Y-Rust) CRDT engine, runs on the `axum` web framework with `tokio` multi-threading, maintains structured collaborative "rooms" via WebSockets, and persists scene state snapshots using the `sled` embedded KV database.

## Key Files
- [Specification](./spec.md)
- [Implementation Plan](./plan.md)
- [Metadata](./metadata.json)
