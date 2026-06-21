# Track 2 Specification: Collaborative Sync Server

## 1. System Architecture

The Synapse Collaborative Server (`synapse-server`) is a lightweight, high-performance, asynchronous Rust service designed to act as an authoritative state synchronization coordinator, persistent store, and telemetry gateway.

```
                   ┌──────────────────────────────────┐
                   │          synapse-server          │
                   │ ──────────────────────────────── │
                   │  [Axum Router]                   │
                   │    ├── /health                   │
                   │    └── /ws/room/:room_id         │
                   └─────────────────┬────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    ▼                                 ▼
         ┌─────────────────────┐           ┌─────────────────────┐
         │     Room Hub        │           │    Sled Database    │
         │  (In-Memory State)  │           │   (Persistence)     │
         │ ─────────────────── │           │ ─────────────────── │
         │  * Room (Yrs Doc)   │◄─────────►│  * Key: room_id     │
         │  * Client Tx Chans  │           │  * Val: binary doc  │
         └─────────────────────┘           └─────────────────────┘
```

## 2. Technical Stack
- **Runtime**: `tokio` (multi-threaded, asynchronous).
- **Web / WebSocket Server**: `axum` + `tokio-tungstenite`.
- **CRDT Core**: `yrs` (Y-Rust) v0.17+ providing Conflict-Free Replicated Data Types.
- **State Persistence**: `sled` v0.34+ (lightweight, lock-free embeddable key-value store in Rust).
- **Serialization / Binary Protocol**: `y-protocols` / raw binary updates for zero-copy synchronization.
- **Observability**: `tracing` + `tracing-subscriber` for structural structured logging.

## 3. Communication Protocol

Clients communicate with the server over WebSocket using binary messages modeled after the Yjs/Y-protocols standard.

### 3.1 Message Frame Format
Each binary WebSocket message is prefixed with a `u8` Message Type:
- `0`: **Sync Step 1 (Client Hello)**: Client sends its local State Vector (`yrs::StateVector`).
- `1`: **Sync Step 2 (Server Response)**: Server calculates the difference and returns missing updates (`yrs::Update`).
- `2`: **Sync Update (Incremental Changes)**: Sent bidirectionally whenever a client makes a change or the server broadcasts updates.
- `3`: **Telemetry Event (High Frequency)**: Sensor updates, 3D transform updates, or active locks that bypass CRDT weight for ultra-low latency broadcasting.

### 3.2 Sync Protocol Flow
1. **Connection Establish**: Client connects to `/ws/room/{room_id}`.
2. **Sync Initiation**:
   - Client sends message `[0, ...state_vector_bytes]`.
   - Server receives, calculates difference against the room's authoritative `YDoc`.
   - Server responds with `[1, ...update_bytes]`.
   - Server then sends its own State Vector `[0, ...server_state_vector_bytes]` to request missing changes from the client.
3. **Continuous Sync**:
   - As users edit properties, client sends incremental `[2, ...update_bytes]`.
   - Server applies update to authoritative `YDoc`, writes to `sled`, and broadcasts `[2, ...update_bytes]` to other connected clients in the room.

## 4. State Persistence (Sled Engine)

- **Database Path**: `data/synapse_db`
- **Store Schema**:
  - Tree Name: `"rooms"`
  - Key: `room_id` (UTF-8 String)
  - Value: Authoritative serialized `YDoc` document bytes (`yrs::Doc::encode_state_as_update_v1`).
- **Sync Strategy**:
  - Updates are applied immediately to the in-memory `YDoc`.
  - A debounced background task flushes the fully merged state of the room to Sled every `1000ms` when modified, avoiding disk I/O bottlenecks.

## 5. Multi-room Hub State

The server tracks rooms in a concurrent global map:
```rust
pub struct Room {
    pub id: String,
    pub doc: yrs::Doc,
    pub peers: HashMap<usize, tokio::sync::mpsc::UnboundedSender<axum::extract::ws::Message>>,
}

pub type RoomHub = Arc<tokio::sync::RwLock<HashMap<String, Arc<tokio::sync::Mutex<Room>>>>>;
```
This ensures safe, concurrent operations across multiple rooms under load.
