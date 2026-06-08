# Data Sender TCP Protocol

Data Sender runs a local TCP server.

Default address:
```text
127.0.0.1:28765
```

## Common Flow

Clients start subscribed to no telemetry sources. After connecting, send the subscription request for the source data you want:

```json
{"type":"subscribe","sources":["vehicle_state"]}
```

The server acknowledges the subscription and immediately sends the latest matching source snapshots it already has.

Enable and configure vehicle state if needed:

```json
{"type":"source.set_enabled","source":"vehicle_state","enabled":true}
{"type":"source.set_interval","source":"vehicle_state","intervalMs":16}
```

Start the service:

```json
{"type":"service.start"}
```

Read newline-delimited messages until the connection closes.

Stop the service:

```json
{"type":"service.stop"}
```

## Commands

### Service Commands

```json
{"type":"service.start"}
{"type":"service.stop"}
{"type":"service.restart"}
{"type":"service.status"}
```

### Source Commands

Enable or disable one source:

```json
{"type":"source.enable","source":"race_data"}
{"type":"source.disable","source":"race_data"}
{"type":"source.set_enabled","source":"vehicle_state","enabled":true}
```

Enable or disable multiple sources:

```json
{"type":"sources.enable","sources":["race_data","vehicle_state"]}
{"type":"sources.disable","sources":["race_data","camera"]}
{"type":"sources.set_enabled","sources":["race_data","not_a_source"],"enabled":true}
```

Batch source commands report accepted and rejected source IDs:

```json
{
  "type": "ack",
  "version": 1,
  "t": 123456,
  "command": "sources.set_enabled",
  "message": "sources enabled",
  "data": {
    "accepted": ["race_data"],
    "rejected": ["not_a_source"],
    "sources": [
      {
        "id": "race_data",
        "label": "Race data",
        "enabled": true,
        "intervalMs": 100
      }
    ]
  }
}
```

Set one source interval:

```json
{"type":"source.set_interval","source":"vehicle_state","intervalMs":16}
```

Intervals are clamped to `1..1000` ms.

List sources:

```json
{"type":"sources"}
{"type":"source.list"}
{"type":"sources.list"}
```

### Subscription Commands

Subscribe to specific sources:

```json
{"type":"subscribe","sources":["race_data","not_a_source"]}
```

The response reports which source IDs were accepted and which were rejected:

```json
{
  "type": "ack",
  "version": 1,
  "t": 123456,
  "command": "subscribe",
  "message": "subscriptions updated",
  "data": {
    "accepted": ["race_data"],
    "rejected": ["not_a_source"],
    "subscription": {
      "all": false,
      "sources": ["race_data"]
    }
  }
}
```

After the acknowledgement, the server immediately sends the latest already sampled snapshots for the accepted subscriptions. If the service has not sampled those sources yet, the snapshots will arrive on the next matching service update.

Subscribe to all sources:

```json
{"type":"subscribe_all"}
```

`subscribe_all` also immediately flushes the latest already sampled snapshots for all sources.

Unsubscribe from specific sources:

```json
{"type":"unsubscribe","sources":["race_data"]}
```

`unsubscribe` also reports accepted and rejected source IDs. Accepted means the source ID exists and the command was applied; it does not require that the source was already subscribed.

Unsubscribe from all sources:

```json
{"type":"unsubscribe","sources":["all"]}
```

## Sources

Current source IDs:

| Source | Description |
| --- | --- |
| `race_data` | MLFeed race/map/player snapshot. |
| `player_cp_info` | Full MLFeed player checkpoint/status snapshot. |
| `vehicle_state` | Local viewed vehicle telemetry. |
| `camera` | Current render camera and viewed vehicle screen projection. |

Source payloads include an `available` field. If a source exists but cannot
produce data, it sends `available: false` with a `reason` field instead of an
empty value.

If a source throws while being sampled, the sender keeps running and emits a
source error payload:

```json
{
  "available": false,
  "reason": "source_error",
  "error": "exception details"
}
```

Common unavailable reasons:

| Source | Reason |
| --- | --- |
| Any source | `source_error` |
| `race_data` | `mlfeed_race_data_dependency_unavailable`, `no_race_data` |
| `player_cp_info` | `mlfeed_race_data_dependency_unavailable`, `no_race_data` |
| `vehicle_state` | `vehicle_state_dependency_unavailable`, `no_viewing_player_state`, `not_sampled_yet` |
| `camera` | `camera_dependency_unavailable`, `no_current_camera` |

### Player CP Info Data

The `player_cp_info` source reports the full MLFeed `PlayerCpInfo_V4` surface
for each player, sorted by race rank:

```json
{
  "available": true,
  "map": "abc123",
  "gameTime": 123456,
  "cpCount": 12,
  "cpsToFinish": 13,
  "lapCount": 1,
  "spawnCount": 4,
  "localPlayer": {
    "name": "Local Player",
    "login": "local-login",
    "wsid": "account-id"
  },
  "players": [
    {
      "name": "Player",
      "login": "player-login",
      "wsid": "account-id",
      "summary": "PlayerCpInfo(...)",
      "isLocalPlayer": false,
      "isMVP": false,
      "isSpawned": true,
      "isFinished": false,
      "spawnStatus": "Spawned",
      "spawnStatusValue": 2,
      "spawnIndex": 1,
      "startTime": 1000,
      "currentLap": 0,
      "cpCount": 5,
      "cpTimes": [0, 8123, 16345],
      "lastCpTime": 43231,
      "lastCpOrRespawnTime": 43231,
      "lastTheoreticalCpTime": 43231,
      "currentRaceTime": 45000,
      "currentRaceTimeRaw": 45016,
      "theoreticalRaceTime": 45000,
      "bestTime": 55992,
      "bestRaceTimes": [8123, 16345],
      "bestLapTimes": [8123, 16345],
      "nbRespawnsRequested": 0,
      "lastRespawnCheckpoint": 0,
      "lastRespawnRaceTime": 0,
      "timeLostToRespawns": 0,
      "timeLostToRespawnByCp": [0, 0, 0],
      "raceRank": 17,
      "raceRespawnRank": 17,
      "taRank": 3,
      "roundPoints": 0,
      "points": 0,
      "teamNum": -1,
      "latencyEstimate": 16.0
    }
  ]
}
```

### Camera Data

The `camera` source reports the current render camera when the Camera dependency
is available:

```json
{
  "available": true,
  "position": [10.0, 20.0, 30.0],
  "fov": 90.0,
  "nearZ": 0.1,
  "farZ": 10000.0,
  "aspect": 1.7777778,
  "drawRect": {
    "min": [-1.0, -1.0],
    "max": [1.0, 1.0]
  },
  "viewingVehicle": {
    "worldPosition": [100.0, 20.0, 200.0],
    "screenPosition": [960.0, 540.0, -1.0],
    "behindCamera": false
  }
}
```

If no render camera is available, `available` is `false` with a `reason` field.

## Server Messages

### Snapshot

Telemetry source messages use `type: "snapshot"`.

```json
{
  "type": "snapshot",
  "version": 1,
  "t": 123456,
  "source": "vehicle_state",
  "sourceLabel": "Vehicle state",
  "seq": 42,
  "data": {
    "available": true,
    "spd": 132.5,
    "pos": [10.0, 20.0, 30.0],
    "gear": 4
  }
}
```

`seq` is per source. Clients only receive a source snapshot when that source has a newer `seq` than the client has already seen.

The TCP server can rate-limit telemetry per client. When the limit is reached, it skips older telemetry messages and sends the latest source snapshot once there is capacity again. Clients should treat `seq` as monotonic, not gap-free.

### Service Status

```json
{
  "type": "service_status",
  "version": 1,
  "t": 123456,
  "source": "service",
  "data": {
    "running": true,
    "clients": 1,
    "sourceSamples": 120,
    "tcp": {
      "messagesSent": 240,
      "telemetryDropped": 12,
      "maxTelemetryMessagesPerSecond": 120
    }
  }
}
```

### Acknowledgement

```json
{
  "type": "ack",
  "version": 1,
  "t": 123456,
  "command": "source.set_enabled",
  "message": "source enabled",
  "data": {
    "source": {
      "id": "vehicle_state",
      "enabled": true,
      "intervalMs": 16
    }
  }
}
```

### Error

```json
{
  "type": "error",
  "version": 1,
  "t": 123456,
  "code": "unknown_source",
  "message": "Unknown source id: nope"
}
```

## Python Example

See [examples/tcp_client.py](examples/tcp_client.py).
