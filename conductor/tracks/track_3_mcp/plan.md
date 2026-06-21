# Track 3 Implementation Plan: Native Rust MCP Server Integration

This plan tracks the setup, implementation, and verification of the native stdio-based MCP server within `synapse-server`.

## Phase 1: Logging Redirection & Command-line Flags
- [x] Implement command-line parser in `src/main.rs` to detect an `--mcp` flag
- [x] If `--mcp` flag is active, redirect standard logging subscriber (`tracing`) to write to `stderr` instead of `stdout`

## Phase 2: JSON-RPC 2.0 Message Envelopes
- [x] Define robust Rust structures representing standard JSON-RPC 2.0 Requests, Responses, and Notifications
- [x] Implement deserialize/serialize schemas for `initialize`, `tools/list`, and `tools/call`

## Phase 3: MCP Handshake & Tool Discovery
- [x] Implement standard input (`stdin`) line-by-line reading thread or async loop
- [x] Respond correctly to `initialize` and `initialized` handshake sequences
- [x] Expose `get_scene_tree`, `add_3d_node`, `update_3d_node`, and `delete_3d_node` inside the `tools/list` response

## Phase 4: yrs CRDT Shared Nodes Mutation & Broadcasting
- [x] Implement `get_scene_tree` tool handler reading yrs `"nodes"` map in the requested room
- [x] Implement `add_3d_node` tool handler, inserting a new JSON string under a generated ID into the yrs map, setting the dirty flag, and multicasting update packets to peers
- [x] Implement `update_3d_node` and `delete_3d_node` handlers mutating yrs values and broadcasting

## Phase 5: Verification & Integration Tests
- [x] Write a comprehensive automated unit/integration test booting the MCP stdin loop and executing tool calls
- [x] Verify that `cargo test` runs and passes with 100% success
- [x] Compile the server under `--release` flag with zero warnings or errors
