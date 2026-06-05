enum WsState { Disconnected, Connecting, Handshaking, Open, Closing }

class WebSocketClient {
    WsState state = WsState::Disconnected;

    WebSocketClient(const string &in url) { ParseUrl(url); }

    // Public API dings

    bool Connect() {
        log("Connecting to " + host + ":" + tostring(port), LogLevel::Info, 11, "Connect");
        if (state != WsState::Disconnected) return false;

        usingTLS = secure;
        if (usingTLS) { @ssock = Net::SecureSocket(); }
        else          { @sock  = Net::Socket(); }

        if (!Conn(host, port)) return false;
        state = WsState::Connecting;
        return true;
    }

    void Update() {
        if ((!usingTLS && sock is null) || (usingTLS && ssock is null)) return;

        if (state == WsState::Connecting && Ready()) PerformHandshake();

        if (state == WsState::Handshaking && Avail() > 0) {
            _hsBuf += Read(Avail());
            if (_hsBuf.IndexOf("101 Switching Protocols") >= 0) {
                state  = WsState::Open;
                _hsBuf = "";
            }
        }

        if (state != WsState::Open) return;

        FlushTx();

        if (Avail() > 0) {
            string frame = Read(Avail());
            if (frame.Length >= 2) {
                uint8 b0 = frame[0];
                uint8 opcode = b0 & 0x0F;
                if (opcode == 0x9) {
                    uint8 len = frame[1] & 0x7F;
                    MemoryBuffer pong;
                    pong.Write(uint8(0x8A));
                    pong.Write(uint8(len));
                    for (uint i = 0; i < len && 2 + int(i) < frame.Length; i++) {
                        pong.Write(uint8(frame[2 + i]));
                    }
                    WriteBuf(pong);
                }
            }
        }

        if (!usingTLS && Hung()) ScheduleReconnect();
    }

    void SendText(const string &in json) {
        if (state == WsState::Open) _txQueue.InsertLast(FrameText(json));
    }

    void Close() {
        CloseSock();
        @sock = null;
        @ssock = null;
        state = WsState::Disconnected;
    }

    // Private helpers

    Net::Socket@       sock;
    Net::SecureSocket@ ssock;
    bool usingTLS = false;

    bool   Conn(const string &in h, uint16 p) {return usingTLS ? ssock.Connect(h, p) : sock.Connect(h, p);}
    bool   Ready()     { return usingTLS ? !ssock.Connecting() : sock.IsReady(); }
    int    Avail()     { return usingTLS ? ssock.Available()   : sock.Available(); }
    string Read(int n) { return usingTLS ? ssock.ReadRaw(n)    : sock.ReadRaw(n); }
    bool   Hung()      { return usingTLS ? false : sock.IsHungUp(); }

    void   CloseSock() {
        if (usingTLS) { if (ssock !is null) ssock.Close(); }
        else          { if (sock  !is null) sock.Close();  }
    }

    void WriteBuf(MemoryBuffer@ buf) {
        buf.Seek(0);
        uint64 sz = buf.GetSize();
        if (usingTLS) { ssock.Write(buf, sz); }
        else          { sock .Write(buf, sz); }
    }

    bool secure;
    string host;
    uint16 port;
    string path;

    void ParseUrl(const string &in url) {
        secure = url.StartsWith("wss://");
        uint pre = secure ? 6 : 5;
        string rest = url.SubStr(pre);
        int slashRel = rest.IndexOf("/");
        int slash = slashRel < 0 ? -1 : pre + slashRel;
        string auth = slash < 0 ? rest : url.SubStr(pre, slashRel);
        int colon = auth.IndexOf(":");

        host = colon < 0 ? auth : auth.SubStr(0, colon);
        port = uint16(colon < 0 ? (secure ? 443 : 80)
                                : Text::ParseUInt(auth.SubStr(colon + 1)));
        path = slash < 0 ? "/" : url.SubStr(slash);
    }

    // Handshake and frame handling

    string _hsBuf;

    void PerformHandshake() {
        log("Performing WebSocket handshake", LogLevel::Info, 121, "PerformHandshake");
        MemoryBuffer keyBuf;
        
        for (uint i = 0; i < 16; i++) {
            keyBuf.Write(uint8(Math::Rand(0,255)));
        }
        keyBuf.Seek(0);
        string wsKey = Text::EncodeBase64(keyBuf.ReadString(16));

        string req =
            "GET "+path+" HTTP/1.1\r\n"
            "Host: "+host+"\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            "Sec-WebSocket-Key: "+wsKey+"\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n";

        MemoryBuffer hdr;
        hdr.Write(req);
        WriteBuf(hdr);
        state = WsState::Handshaking;
    }

    array<MemoryBuffer@> _txQueue;

    void FlushTx() {
        while (_txQueue.Length > 0) {
            WriteBuf(_txQueue[0]);
            _txQueue.RemoveAt(0);
        }
    }

    void WriteByte(MemoryBuffer@ b, uint8 v) { b.Write(v); }

    MemoryBuffer@ FrameText(const string &in payload) {
        const uint n = payload.Length;
        MemoryBuffer@ buf = MemoryBuffer();

        WriteByte(buf, 0x81);

        if (n <= 125) {
            WriteByte(buf, uint8(0x80 | n));
        } else if (n < 65536) {
            WriteByte(buf, 0x80 | 126);
            WriteByte(buf, uint8((n >> 8) & 0xFF));
            WriteByte(buf, uint8(n & 0xFF));
        } else {
            WriteByte(buf, 0x80 | 127);
            for (int s = 56; s >= 0; s -= 8) {
                WriteByte(buf, uint8((uint64(n) >> s) & 0xFF));
            }
        }

        uint8 k0 = uint8(Math::Rand(0, 255));
        uint8 k1 = uint8(Math::Rand(0, 255));
        uint8 k2 = uint8(Math::Rand(0, 255));
        uint8 k3 = uint8(Math::Rand(0, 255));
        WriteByte(buf, k0); WriteByte(buf, k1); WriteByte(buf, k2); WriteByte(buf, k3);

        for (uint i = 0; i < n; i++) {
            uint8 m = (i & 3) == 0 ? k0
                    : (i & 3) == 1 ? k1
                    : (i & 3) == 2 ? k2 : k3;
            WriteByte(buf, uint8(payload[i]) ^ m);
        }
        return buf;
    }

    void ScheduleReconnect() {
        Close();
        startnew(_Reconnect, @this);
    }
}

void _Reconnect(ref@ r) {
    WebSocketClient@ ws = cast<WebSocketClient>(r);
    while (ws.state != WsState::Open) {
        sleep(3000);
        if (ws.state == WsState::Disconnected) ws.Connect();
    }
}