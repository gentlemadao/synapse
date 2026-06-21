# Track 2 Implementation Plan: Collaborative Sync Server

This plan tracks the setup, implementation, and verification of the independent collaborative sync server project.

## Phase 1: Project Setup & Dependencies
- [x] Create brand new Rust cargo project (`synapse-server`) in parent directory
- [x] Add Tokio, Axum, Yrs, Sled, Tracing, and Tower-HTTP dependencies to `Cargo.toml`
- [x] Configure structured logging with `tracing` and set up the health endpoint

## Phase 2: In-Memory Room Hub & State Definition
- [x] Define the `Room` and `RoomHub` concurrent models
- [x] Implement robust room retrieval logic (create if not exists, loading initial state)
- [x] Add unit tests for `Room` initialization and message broadcast structures

## Phase 3: Sled Database Persistence Layer
- [x] Initialize the `sled` database engine at `data/synapse_db`
- [x] Write logic to fetch a room's state vector on demand from Sled
- [x] Write background task to periodically flush modified `YDoc` memory states to Sled
- [x] Add unit tests verifying Sled save/load operations of `YDoc` states

## Phase 4: WebSocket Synchronization Handlers
- [x] Implement the Axum WebSocket handler routing connections from `/ws/room/:room_id`
- [x] Write parsing logic for the binary prefix protocol (Sync Step 1, Sync Step 2, Incremental Update)
- [x] Add a connection and disconnection tracking system to clean up dead peers
- [x] Implement room broadcasting for both standard CRDT and raw telemetry packets

## Phase 5: Verification & Integration Tests
- [x] Write a complete client-server simulation integration test using `tokio-tungstenite`
- [x] Run `cargo test` to ensure 100% of the server unit/integration tests pass
- [x] Verify that the server builds under `--release` flag with zero warnings or compilation errors
