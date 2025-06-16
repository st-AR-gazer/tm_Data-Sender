"""
Hallooo!! This is a simple Dual-channel WebSocket Test Server 
I was using to test if the feed and vehicle state channels 
were working correctly. 

This script listens on two WebSocket endpoints to verify and log data
streams from the companion Openplanet plugin:

  * /feed   - Receives JSON snapshots of race data
  * /vstate - Receives per-frame vehicle telemetry

Usage:
    # Listen on both channels (default)
    python feed_server.py

    # Listen only on the race snapshot channel
    python feed_server.py --mode feed

    # Listen only on the vehicle state channel
    python feed_server.py --mode vstate

Arguments:
    --mode  one of: both, feed, vstate   (default: both)

Logging:
    * Incoming JSON is pretty-printed to the console.
    * Non-JSON or protocol errors are logged with context.

To integrate into a larger system, replace the logging calls in
`router()` with your own processing, storage, or forwarding logic.
"""


import argparse
import asyncio
import json
import logging
from typing import Set

import websockets
from websockets import serve
from websockets.legacy.server import WebSocketServerProtocol

argp = argparse.ArgumentParser()
argp.add_argument("--mode", choices=("both", "feed", "vstate"), default="both", help="channel selection (default: both)")
MODE = argp.parse_args().mode

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s: %(message)s")

ALLOWED_PATHS = {
    "both":   {"/feed", "/vstate"},
    "feed":   {"/feed"},
    "vstate": {"/vstate"},
}[MODE]

clients: Set[WebSocketServerProtocol] = set()

def ws_path(ws: WebSocketServerProtocol) -> str:
    return (getattr(getattr(ws, "request", None), "path", None) or getattr(ws, "path", "/"))


async def router(ws: WebSocketServerProtocol):
    path = ws_path(ws)
    if path not in ALLOWED_PATHS:
        logging.warning("Reject %s on %s", ws.remote_address, path)
        await ws.close(code=1008, reason="unsupported path")
        return

    clients.add(ws)
    logging.info("Connect %s → %s", ws.remote_address, path)

    try:
        async for raw in ws:
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                logging.error("Bad JSON on %s: %.80s", path, raw)
                continue

            if path == "/feed":
                logging.info("Race:\n%s", json.dumps(data, indent=2))
            else: # == "/vstate":
                logging.info("VState:\n%s", json.dumps(data, indent=2))

    except websockets.ConnectionClosedOK:
        pass
    except websockets.ConnectionClosedError as exc:
        logging.warning("Closed with error: %s", exc)
    finally:
        clients.discard(ws)
        logging.info("Disconnect %s", ws.remote_address)


async def main():
    human_paths = ", ".join(sorted(ALLOWED_PATHS))
    async with serve(router, "127.0.0.1", 8765, ping_interval=None, ping_timeout=None):
        logging.info("Listening on ws://127.0.0.1:8765{%s}", human_paths)
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Server stopped")
