# Data Sender TCP Protocol

Data Sender runs a local TCP server.

Default address:
```text
127.0.0.1:8765
```

## Common Flow

Start the service:

```json
{"type":"service.start"}
```

Enable and subscribe to vehicle state:

```json
{"type":"source.set_enabled","source":"vehicle_state","enabled":true}
{"type":"source.set_interval","source":"vehicle_state","intervalMs":16}
{"type":"subscribe","sources":["vehicle_state"]}
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

Subscribe to all sources:

```json
{"type":"subscribe_all"}
```

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

```text
race_data
vehicle_state
camera
server_info
```

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
    "spd": 132.5,
    "pos": [10.0, 20.0, 30.0],
    "gear": 4
  }
}
```

`seq` is per source. Clients only receive a source snapshot when that source has a newer `seq` than the client has already seen.

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
    "sourceSamples": 120
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
