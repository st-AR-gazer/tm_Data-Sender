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

- `race_data`
- `vehicle_state`
- `camera`
- `server_info`
