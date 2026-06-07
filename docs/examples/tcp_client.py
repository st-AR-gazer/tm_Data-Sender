import argparse
import json
import socket


def send(sock, message):
    raw = json.dumps(message, separators=(",", ":")) + "\n"
    sock.sendall(raw.encode("utf-8"))


def receive_lines(sock):
    buffer = ""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            return

        buffer += chunk.decode("utf-8", errors="replace")
        while "\n" in buffer:
            line, buffer = buffer.split("\n", 1)
            line = line.strip()
            if line:
                yield line


def main():
    parser = argparse.ArgumentParser(description="Data Sender TCP example client")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument(
        "--source",
        action="append",
        default=["vehicle_state"],
        help="Source to subscribe to. Can be passed more than once.",
    )
    parser.add_argument("--start", action="store_true", help="Start the sender service")
    args = parser.parse_args()

    with socket.create_connection((args.host, args.port)) as sock:
        if args.start:
            send(sock, {"type": "service.start"})

        for source in args.source:
            send(
                sock, {"type": "source.set_enabled", "source": source, "enabled": True}
            )

        send(sock, {"type": "subscribe", "sources": args.source})
        send(sock, {"type": "service.status"})

        print(f"Connected to {args.host}:{args.port}; press Ctrl+C to stop.")
        for line in receive_lines(sock):
            try:
                message = json.loads(line)
            except json.JSONDecodeError:
                print(f"bad json: {line}")
                continue

            message_type = message.get("type")
            source = message.get("source", "")
            seq = message.get("seq", "")
            print(f"{message_type} {source} {seq}")
            print(json.dumps(message, indent=2))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Stopped.")
