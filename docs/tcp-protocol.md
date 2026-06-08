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
| `race_data` | `MLFeed::GetRaceData_V4()` race/map state. |
| `player_cp_info` | Full `MLFeed::PlayerCpInfo_V4` checkpoint/status snapshot. |
| `vehicle_state` | Local viewed vehicle state, including inputs, pose, velocity, reactor/turbo, water/contact, engine, and wheels. |
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

### Race Data

The `race_data` source reports the serializable JSON surface of
`MLFeed::HookRaceStatsEventsBase_V4`, returned by `MLFeed::GetRaceData_V4()`.
Sorted player arrays are exported as ordered player references so this source
stays focused on race/map state. Full `MLFeed::PlayerCpInfo_V4` data lives in
the `player_cp_info` source. Object handles such as player nod handles are not
serialized.

`players` is a convenience alias for `sortedPlayers.race`.

```json
{
  "available": true,
  "map": "abc123",
  "gameTime": 123456,
  "localPlayersName": "Local Player",
  "localPlayersLoginIdValue": 12345,
  "cpCount": 12,
  "cpsToFinish": 13,
  "lapCount": 1,
  "lapCountRaw": 1,
  "lapsNb": 1,
  "spawnCount": 4,
  "updateNonce": 12,
  "lastRecordTime": -1,
  "rules": {
    "gameTime": 123456,
    "startTime": 1000,
    "endTime": -1,
    "millisSinceStart": 122456,
    "timeElapsed": 122456,
    "timeRemaining": -1
  },
  "warmup": {
    "active": false,
    "endTime": 0
  },
  "playersLeft": {
    "batchNumber": 0,
    "names": [],
    "loginIdValues": []
  },
  "cotdQualification": {
    "localRaceTime": 0,
    "apiRaceTime": 0,
    "rank": 0,
    "joinTime": 0,
    "stage": "Null",
    "stageValue": 0,
    "isSynchronizingRecord": false,
    "updateNonce": 0
  },
  "localPlayer": {
    "name": "Local Player",
    "login": "local-login",
    "wsid": "account-id"
  },
  "playerCounts": {
    "race": 1,
    "raceRespawns": 1,
    "timeAttack": 1
  },
  "players": [],
  "sortedPlayers": {
    "race": [],
    "raceRespawns": [],
    "timeAttack": []
  }
}
```

### Player CP Info Data

The `player_cp_info` source reports the serializable
`MLFeed::PlayerCpInfo_V4` surface for players discovered through
`MLFeed::GetRaceData_V4()`, including race/race-respawn/time-attack sorted
views. This source is useful for a slower, debugging-friendly full
checkpoint/status snapshot.

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
      "loginMwId": {
        "value": 12345,
        "name": "player-login"
      },
      "nameMwId": {
        "value": 67890,
        "name": "Player"
      },
      "isLocalPlayer": false,
      "isMVP": false,
      "isSpawned": true,
      "isFinished": false,
      "playerIsRacing": true,
      "eliminated": false,
      "requestsSpectate": false,
      "spawnStatus": "Spawned",
      "spawnStatusValue": 2,
      "spawnIndex": 1,
      "spawnCount": 1,
      "startTime": 1000,
      "currentLap": 0,
      "updateNonce": 5,
      "firstSeen": 12345,
      "cpCount": 5,
      "cpTimes": [0, 8123, 16345],
      "lastCpTime": 43231,
      "finishTime": 2147483647,
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
      "nbRespawnsByCp": [0, 0, 0],
      "respawnTimes": [],
      "raceRank": 17,
      "raceRespawnRank": 17,
      "taRank": 3,
      "roundPoints": 0,
      "points": 0,
      "teamNum": -1,
      "latencyEstimate": 16.0,
      "raceProgression": {
        "x": 0,
        "y": 0,
        "points": 0,
        "time": 0
      },
      "raceProgressionHistory": [],
      "royalTAHasFinished": false,
      "royalTASegmentsFinished": 0,
      "koState": {
        "name": "Player",
        "isAlive": true,
        "isDNF": false
      }
    }
  ]
}
```

### Vehicle State Data

The `vehicle_state` source reports the currently viewed vehicle state from the
VehicleState dependency. The top-level shorthand fields are kept for quick
clients and smoke captures, while `vehicleState` contains the richer grouped
state.

```json
{
  "available": true,
  "spd": 72.4,
  "sspd": -1.2,
  "frontSpeed": 72.1,
  "pos": [10.0, 20.0, 30.0],
  "worldVel": [72.0, 0.0, 2.0],
  "steer": -0.1,
  "throttle": 1.0,
  "brake": 0.0,
  "gear": 4,
  "FL": {
    "steerAngle": -0.05,
    "wheelRot": 1.2,
    "wheelRotSpeed": 41.5,
    "damperLen": 0.08,
    "slipCoef": 0.02,
    "groundContactMaterial": 0
  },
  "vehicleState": {
    "pose": {
      "position": [10.0, 20.0, 30.0],
      "left": [1.0, 0.0, 0.0],
      "up": [0.0, 1.0, 0.0],
      "dir": [0.0, 0.0, 1.0]
    },
    "velocity": {
      "speed": 72.4,
      "speedKph": 260.64,
      "frontSpeed": 72.1,
      "sideSpeed": -1.2,
      "acceleration": 3.2,
      "jerk": 0.5
    },
    "inputs": {
      "steer": -0.1,
      "gasPedal": 1.0,
      "brakePedal": 0.0,
      "isBraking": false
    },
    "engine": {
      "rpm": 8800.0,
      "curGear": 4,
      "lastTurboLevel": "Normal",
      "cruiseDisplaySpeed": 0,
      "vehicleType": "CarSport"
    },
    "wheels": {
      "frontLeft": {},
      "frontRight": {},
      "rearLeft": {},
      "rearRight": {}
    }
  }
}
```

### Camera Data

The `camera` source reports the current render camera when the Camera dependency
is available:

```json
{
  "available": true,
  "camera": {
    "isActive": true,
    "position": [10.0, 20.0, 30.0],
    "location": {
      "translation": [10.0, 20.0, 30.0],
      "matrix": [
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [10.0, 20.0, 30.0, 1.0]
      ]
    },
    "nextLocation": {
      "translation": [10.0, 20.0, 30.0],
      "matrix": [
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [10.0, 20.0, 30.0, 1.0]
      ]
    },
    "m_IsPickEnable": true,
    "m_UseViewDependantRendering": true,
    "m_ViewportRatio": "FovY",
    "m_ViewportRatioValue": 1,
    "m_IsOverlay3d": false,
    "clearColorEnable": false,
    "clearColor": [0.0, 0.0, 0.0],
    "m_UseZBuffer": true,
    "scissorRect": false,
    "fovRect": false,
    "clearZBuffer": true,
    "drawRect": {
      "min": [-1.0, -1.0],
      "max": [1.0, 1.0]
    },
    "scissor": {
      "min": [-1.0, -1.0],
      "max": [1.0, 1.0]
    },
    "fovRectBounds": {
      "min": [-1.0, -1.0],
      "max": [1.0, 1.0]
    },
    "nearZ": 0.1,
    "farZ": 10000.0,
    "fov": 90.0,
    "clampFovX": 0.0,
    "clampFovY": 0.0,
    "clampFovAuto": false,
    "clampFovRatioXy": 1.7777778,
    "widthHeight": 1.7777778,
    "m_PickerAvailable": true,
    "m_GroupIndex": 0,
    "m_IsInternal": 0,
    "waterTop": 0.0,
    "waterIndex": 0,
    "isJustAboveWater": 0,
    "isInsideWater": 0
  },
  "projection": {
    "cameraMatrix": [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [10, 20, 30, 1]],
    "viewMatrix": [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [-10, -20, -30, 1]],
    "projectionMatrix": [[0.5625, 0, 0, 0], [0, 1, 0, 0], [0, 0, -1.00002, -1], [0, 0, -0.200002, 0]],
    "viewProjectionMatrix": [[0.5625, 0, 0, 0], [0, 1, 0, 0], [0, 0, -1.00002, -1], [-5.625, -20, 29.8006, 30]],
    "cameraPluginProjectionMatrix": [[0.5625, 0, 0, 0], [0, 1, 0, 0], [0, 0, -1.00002, -1], [-5.625, -20, 29.8006, 30]],
    "nextCameraMatrix": [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [10, 20, 30, 1]],
    "displaySize": [1920.0, 1080.0],
    "displayPos": [0.0, 0.0],
    "displayProjectedSize": [1920.0, 1080.0],
    "drawRect": {
      "min": [-1.0, -1.0],
      "max": [1.0, 1.0]
    },
    "toScreenBehindWhenWGreaterThanZero": true
  },
  "viewingVehicle": {
    "worldPosition": [100.0, 20.0, 200.0],
    "screenPosition": [960.0, 540.0, -1.0],
    "behindCamera": false
  }
}
```

Matrices are encoded as four column vectors. `projection.viewProjectionMatrix`
is the matrix used by the Camera dependency's `ToScreen` implementation.
External clients can project a world point with:

```text
clip = viewProjectionMatrix * [x, y, z, 1]
screen = displayPos + ((clip.xy / clip.w + 1) / 2) * displayProjectedSize
behindCamera = clip.w > 0
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

To start the sender service and capture every received TCP message to JSONL:

```powershell
python docs/examples/tcp_capture_smoke.py --duration 30
```
