import argparse
import json
import socket
import time
from pathlib import Path

DEFAULT_SOURCES = ["race_data", "player_cp_info", "vehicle_state", "camera"]


def send(sock, message):
    raw = json.dumps(message, separators=(",", ":")) + "\n"
    sock.sendall(raw.encode("utf-8"))


def try_send(sock, message):
    try:
        send(sock, message)
        return True
    except OSError:
        return False


def close_capture_connection(sock):
    try_send(sock, {"type": "unsubscribe", "sources": ["all"]})
    try:
        sock.shutdown(socket.SHUT_RDWR)
    except OSError:
        pass


def default_output_path():
    stamp = time.strftime("%Y%m%d-%H%M%S")
    plugin_root = Path(__file__).resolve().parents[2]
    return plugin_root / "dumps" / f"data_sender_capture_{stamp}.jsonl"


def read_available_lines(sock, buffer):
    try:
        chunk = sock.recv(65536)
    except TimeoutError:
        return buffer, []

    if not chunk:
        raise RuntimeError("server closed the connection")

    buffer += chunk.decode("utf-8", errors="replace")
    lines = []
    while "\n" in buffer:
        line, buffer = buffer.split("\n", 1)
        line = line.strip()
        if line:
            lines.append(line)
    return buffer, lines


def wait_for_source_registry(sock, timeout):
    deadline = time.monotonic() + timeout
    buffer = ""
    pending_lines = []

    send(sock, {"type": "sources"})
    while time.monotonic() < deadline:
        buffer, lines = read_available_lines(sock, buffer)
        for line in lines:
            pending_lines.append(line)
            message = json.loads(line)
            if message.get("type") != "ack" or message.get("command") != "sources":
                continue

            sources = message.get("data", {}).get("sources", [])
            source_ids = [
                source.get("id")
                for source in sources
                if isinstance(source, dict) and source.get("id")
            ]
            if source_ids:
                return source_ids, pending_lines

    return list(DEFAULT_SOURCES), pending_lines


def main():
    parser = argparse.ArgumentParser(
        description="Capture Data Sender TCP output to a JSONL file."
    )
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=28765)
    parser.add_argument("--duration", type=float, default=30.0)
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--source", action="append", default=None)
    parser.add_argument("--max-messages", type=int, default=0)
    parser.add_argument("--no-start-service", action="store_true")
    parser.add_argument("--keep-source-settings", action="store_true")
    parser.add_argument("--stop-service-at-end", action="store_true")
    parser.add_argument("--connect-timeout", type=float, default=5.0)
    args = parser.parse_args()

    output = args.output or default_output_path()
    output.parent.mkdir(parents=True, exist_ok=True)

    counts = {}
    source_counts = {}
    written = 0
    start = time.monotonic()
    end = start + max(args.duration, 0.0)

    print(f"connecting to {args.host}:{args.port}")
    try:
        sock = socket.create_connection(
            (args.host, args.port), timeout=args.connect_timeout
        )
    except OSError as exc:
        raise RuntimeError(
            "could not connect to the Data Sender TCP server. "
            "Enable the TCP server in Data Sender settings first; this script starts "
            "the sender service after connecting, but it cannot start the TCP listener "
            "without an existing connection."
        ) from exc

    with sock:
        sock.settimeout(0.25)

        registry_sources = []
        pending_lines = []
        if args.source is None:
            registry_sources, pending_lines = wait_for_source_registry(sock, 3.0)
            capture_sources = registry_sources
            subscribe_all = True
        else:
            capture_sources = args.source
            subscribe_all = False

        if not args.keep_source_settings and capture_sources:
            send(
                sock,
                {
                    "type": "sources.set_enabled",
                    "sources": capture_sources,
                    "enabled": True,
                },
            )

        if subscribe_all:
            send(sock, {"type": "subscribe_all"})
        else:
            send(sock, {"type": "subscribe", "sources": capture_sources})

        if not args.no_start_service:
            send(sock, {"type": "service.start"})

        send(sock, {"type": "service.status"})

        print(f"writing capture to {output}")
        with output.open("w", encoding="utf-8", newline="\n") as handle:
            for line in pending_lines:
                handle.write(line + "\n")
                written += 1

            buffer = ""
            while time.monotonic() < end:
                buffer, lines = read_available_lines(sock, buffer)
                for line in lines:
                    handle.write(line + "\n")
                    written += 1

                    try:
                        message = json.loads(line)
                    except json.JSONDecodeError:
                        counts["bad_json"] = counts.get("bad_json", 0) + 1
                        continue

                    message_type = str(message.get("type", "unknown"))
                    counts[message_type] = counts.get(message_type, 0) + 1
                    if message_type == "snapshot":
                        source = str(message.get("source", "unknown"))
                        source_counts[source] = source_counts.get(source, 0) + 1

                    if args.max_messages > 0 and written >= args.max_messages:
                        break

                if args.max_messages > 0 and written >= args.max_messages:
                    break

            handle.flush()

        if args.stop_service_at_end:
            try_send(sock, {"type": "service.stop"})

        print("closing capture connection")
        close_capture_connection(sock)

    print(f"captured {written} messages")
    if counts:
        print("message types: " + json.dumps(counts, sort_keys=True))
    if source_counts:
        print("snapshots: " + json.dumps(source_counts, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("stopped")
    except Exception as exc:
        print(f"FAIL {exc}")
        raise SystemExit(1)
