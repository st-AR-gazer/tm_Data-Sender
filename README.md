![Signed](https://img.shields.io/badge/Signed-No-FF3333)
![Trackmania2020](https://img.shields.io/badge/Game-Trackmania-blue)

# Data Sender


*A tiny guide for grabbing race + vehicle-state data over sockets.*

The current architecture is a local TCP server. External clients connect to the plugin, subscribe to sources, and can optionally control the sender service and source settings.

## Quick Start

1. Open the Data Sender settings in Openplanet.
2. Enable the TCP server.
3. Start the Data Sender service from settings, the render menu, or an external command.
4. Connect to `127.0.0.1:8765`.

## Docs

- [TCP protocol](docs/tcp-protocol.md)
- [Python TCP example](docs/examples/tcp_client.py)

## Sources

Current source IDs:

- `race_data`: MLFeed race/map/player snapshot
- `player_cp_info`: full MLFeed player checkpoint/status snapshot
- `vehicle_state`: local viewed vehicle telemetry
- `camera`: current render camera and viewed vehicle screen projection

Sources backed by optional dependencies report `available: false` with a reason
when that dependency or game state is unavailable.
