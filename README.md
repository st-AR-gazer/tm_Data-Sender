![Signed](https://img.shields.io/badge/Signed-No-FF3333)
![Trackmania2020](https://img.shields.io/badge/Game-Trackmania-blue)

### Trackmania 2020 — DataSender Plugin Docs

*A tiny guide for grabbing race + vehicle-state data over WebSockets.*

---

#### What this plugin does

| Channel           | Endpoint                       | Payload                                                    | Rate            | Purpose                                          |
| ----------------- | ------------------------------ | ---------------------------------------------------------- | --------------- | ------------------------------------------------ |
| **Race feed**     | `ws://127.0.0.1:{PORT}/feed`   | One JSON "snapshot" per interval (map, CPs, players, etc.) | `SEND_EVERY_MS` | Live leaderboard / HUDs / data logging           |
| **Vehicle state** | `ws://127.0.0.1:{PORT}/vstate` | Per-frame car telemetry (pos, speed, slip, RPM ...)        | Every frame     | Motion rigs, analytics, fancy overlays, training |

---

#### Configuring

Open the *General* tab in the Openplanet overlay (F3):

| Setting                               | Meaning                                     | Default               |
| ------------------------------------- | ------------------------------------------- | --------------------- |
| **Send every (ms)** (`SEND_EVERY_MS`) | Snapshot                                    | **1 ms** (max ≈1 kHz) |
| **Port** (`PORT`)                     | TCP port used by both channels              | **8765**              |
| **Automatic startup on plugin load**  | Fire up sockets as soon as the script loads | **off**               |

Buttons: **connect / reconnect / restart server + connect / disconnect / Reset to defaults** – self-explanatory.

---

### Quick-start receiver (Python)

```bash
# 1 Install deps (once)
pip install websockets

# 2 Run the dual-channel logger
python feed_server.py          # or  python feed_server.py --mode feed|vstate|both
```

When the plugin connects you'll see pretty-printed JSON dumps like:

```json
{
  "map": "Stadium C-05",
  "gameTime": 123450,
  "cpCount": 12,
  "players": [
    {
      "name": "Zoop",
      "login": "zoop123",
      "raceRank": 1,
      "bestMs": 56234,
      "respawns": 0
    }
  ]
}
```

Vehicle snapshots contain fields such as `spd`, `pos`, `rpm`, `slipFL`, `gear`, etc. (see `vstate.as` for all fields).

---

### Integrating into your project

* Replace the `logging.info(...)` lines in **`feed_server.py`** with whatever pipeline you need—DB insert, OSC forwarder, HTTP POST, etc etc etc
* Writing your own client? Any WebSocket library will do—just subscribe to `/feed` and/or `/vstate` and parse JSON.
* Remember to handle reconnects: the client in `client.as` will automatically try again every 3 s if the socket dies.
