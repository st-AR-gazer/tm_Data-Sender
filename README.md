![Signed](https://img.shields.io/badge/Signed-No-FF3333)
![Trackmania2020](https://img.shields.io/badge/Game-Trackmania-blue)

# Data Sender


*A tiny guide for grabbing race + vehicle-state data over sockets.*

The current architecture is a local TCP server. External clients connect to the plugin, subscribe to sources, and can optionally control the sender service and source settings.

## Quick Start

1. Open the Data Sender settings in Openplanet.
2. Enable the TCP server.
3. Start the Data Sender service from settings, the render menu, or an external command.
4. Connect to `127.0.0.1:28765`.

## Docs

- [TCP protocol](docs/tcp-protocol.md)
- [Python TCP example](docs/examples/tcp_client.py)
- [Python TCP capture smoke](docs/examples/tcp_capture_smoke.py)

Capture a short JSONL dump:

```powershell
python docs/examples/tcp_capture_smoke.py --duration 30
```

## Sources

Current source IDs:

- `race_data`: `MLFeed::GetRaceData_V4()` race/map state
- `player_cp_info`: full `MLFeed::PlayerCpInfo_V4` checkpoint/status snapshot
- `vehicle_state`: local viewed vehicle state, including inputs, pose, velocity, engine/reactor state, and wheels
- `camera`: current render-phase camera and viewed vehicle screen projection

Sources backed by optional dependencies report `available: false` with a reason
when that dependency or game state is unavailable.
