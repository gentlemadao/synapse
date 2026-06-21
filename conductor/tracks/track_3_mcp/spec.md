# Track 3 Specification: Native Rust MCP Server Integration

## 1. Protocol Architecture

The Synapse Collaborative Server is expanded to include a **Native stdio-based MCP Server**. When spawned by an LLM client, the server reads JSON-RPC 2.0 messages from standard input (`stdin`) and writes responses to standard output (`stdout`).

```
                ┌──────────────────────────────────┐
                │          LLM Client (AI)         │
                └─────────────────┬────────────────┘
                                  │ stdio (JSON-RPC 2.0 over stdin/stdout)
                                  ▼
         ┌──────────────────────────────────────────────────┐
         │             synapse-server (MCP Task)            │
         │ ──────────────────────────────────────────────── │
         │  * Stdio parsing loop (Lines of JSON-RPC)        │
         │  * Direct access to yrs authoritative RoomHub    │
         └────────────────────────┬─────────────────────────┘
                                  │ Direct in-memory lock
                                  ▼
         ┌──────────────────────────────────────────────────┐
         │                    Room Hub                      │
         │ ──────────────────────────────────────────────── │
         │  * yrs::Doc -> Shared Map ("nodes")              │
         │  * Multicasts updates to Flutter/Bevy clients    │
         └──────────────────────────────────────────────────┘
```

> **CRITICAL PERFORMANCE RULE**: Because `stdout` is used for the MCP JSON-RPC stream, all standard server logging (`info!`, `warn!`, `error!`) must be re-routed exclusively to **`stderr`** to prevent protocol stream corruption.

## 2. Shared yrs Schema ("nodes" Map)
Collaborative scene elements are stored inside theyrs document under a shared `MapRef` named `"nodes"`:
- **Key**: node ID (e.g. `"node_7"`)
- **Value**: UTF-8 JSON-serialized string of the node properties:
  ```json
  {
    "id": "node_7",
    "name": "Model_Chair_01",
    "type": "GLB Mesh",
    "px": 0.0,
    "py": -0.5,
    "pz": 0.0,
    "scale": 1.2,
    "color": "#448AFF",
    "visible": true
  }
  ```
Using a flat JSON string inside a yrs map guarantees high-performance serialization, excellent cross-platform type safety with Flutter/Dart, and simplifies direct mutations via MCP tools.

## 3. Supported MCP Tools

The server registers and implements the following tools:

### 3.1 `get_scene_tree`
- **Description**: Returns all 3D nodes and their spatial/transform properties inside a specified room.
- **Arguments**:
  - `room_id` (String): The collaborative room to query.
- **Returns**: Array of node JSON objects.

### 3.2 `add_3d_node`
- **Description**: Inserts a new 3D object into a collaborative room.
- **Arguments**:
  - `room_id` (String): The room to modify.
  - `name` (String): Display name of the object.
  - `node_type` (String): e.g. `"Cuboid"`, `"Sphere"`, `"Cylinder"`, `"GLB Mesh"`.
  - `px` (number), `py` (number), `pz` (number): Spatial translation coordinates.
  - `scale` (number, optional, default: `1.0`): Scale factor.
  - `color` (String, optional, default: `"#FFFFFF"`): Hex color string.
- **Returns**: Confirmation message and the generated node ID.

### 3.3 `update_3d_node`
- **Description**: Updates the position, scale, color, or visibility of an existing node.
- **Arguments**:
  - `room_id` (String): The room containing the node.
  - `id` (String): Node ID to update.
  - `px`, `py`, `pz` (number, optional): Update position.
  - `scale` (number, optional): Update scale.
  - `color` (String, optional): Update hex color.
  - `visible` (bool, optional): Update visibility.
- **Returns**: Confirmation of the update.

### 3.4 `delete_3d_node`
- **Description**: Removes a 3D node from the room.
- **Arguments**:
  - `room_id` (String): The room to modify.
  - `id` (String): Node ID to remove.
- **Returns**: Confirmation of removal.

## 4. JSON-RPC Message Format

Standard JSON-RPC 2.0 envelopes are parsed asynchronously using `serde_json`.

### 4.1 Initialize Request
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": { "name": "Gemini-CLI", "version": "1.0.0" }
  }
}
```

### 4.2 Initialize Response
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {}
    },
    "serverInfo": { "name": "synapse-mcp-server", "version": "0.1.0" }
  }
}
```
