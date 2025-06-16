
enum State {
    Disconnected, Connecting, Handshaking, Open, Closing
}

class WebSocketClient {
    State state = State::Disconnected;

    Net::Socket@       sock;  // for ws://
    Net::SecureSocket@ ssock; // for wss://
    bool usingTLS = false;

    bool   secure;
    string host;
    uint16 port;
    string path;

    string        wsKey;
    array<string> _txQueue;

    /* helpers for no invalid casts) */
    bool   Conn(const string &in h, uint16 p) { return usingTLS ? ssock.Connect(h, p) : sock.Connect(h, p); }

    bool   Ready()     { return usingTLS ? !ssock.Connecting()  : sock.IsReady(); }

    int    Avail()     { return usingTLS ? ssock.Available()    : sock.Available(); }
    
    string Read(int n) { return usingTLS ? ssock.ReadRaw(n)     : sock.ReadRaw(n); }
    
    void   Write(const string &in s) { 
        if (usingTLS) { ssock.WriteRaw(s); } else { sock.WriteRaw(s); } }
    
    void   CloseSock() { if (usingTLS) { if (ssock !is null) ssock.Close(); } 
                                         else { if (sock !is null) sock.Close(); } }

    bool   Hung()      { return usingTLS ? false /* no API */   : sock.IsHungUp(); }

    WebSocketClient(const string &in url) { ParseUrl(url); }

    bool Connect() {
        if (state != State::Disconnected) return false;

        usingTLS = secure;
        if (usingTLS) @ssock = Net::SecureSocket();
        else          @sock  = Net::Socket();

        if (!Conn(host, port)) return false;
        state = State::Connecting;
        return true;
    }

    string _hsBuf; 

    void Update() {
        if ((!usingTLS && sock is null) || (usingTLS && ssock is null)) return;

        if (state == State::Connecting && Ready()) PerformHandshake();

        if (state == State::Handshaking && Avail() > 0) {
        _hsBuf += Read(Avail());
        if (_hsBuf.IndexOf("101 Switching Protocols") >= 0) {
            state  = State::Open;
            _hsBuf = "";
        }
    }

        if (state == State::Open) {
            FlushTx();
            if (Avail() > 0) Read(Avail()); // discard
            if (!usingTLS && Hung()) ScheduleReconnect();
        }
    }

    void SendText(const string &in msg) {
        if (state == State::Open) _txQueue.InsertLast(FrameText(msg));
    }

    void Close() {
        CloseSock();
        @sock = null; @ssock = null;
        state = State::Disconnected;
    }

    void PerformHandshake() {
        MemoryBuffer mb;
        for (uint i = 0; i < 16; i++) {
            mb.Write(uint8(Math::Rand(0, 255)));
        }

        mb.Seek(0);
        string rawKey = mb.ReadString(16);
        wsKey = Text::EncodeBase64(rawKey);

        string req =
            "GET " + path + " HTTP/1.1\r\n"
            "Host: " + host + "\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            "Sec-WebSocket-Key: " + wsKey + "\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n";
        Write(req);
        state = State::Handshaking;
    }

    void FlushTx() {
        while (_txQueue.Length > 0) {
            Write(_txQueue[0]);
            _txQueue.RemoveAt(0);
        }
    }

    string FrameText(const string &in payload) {
        MemoryBuffer buf;

        buf.Write(uint8(0x81));

        uint len = payload.Length;

        if (len <= 125) {
            buf.Write(uint8(0x80 | uint8(len)));
        } else if (len < 65536) {
            buf.Write(uint8(0x80 | 126));
            buf.Write(uint8((len >> 8) & 0xFF));
            buf.Write(uint8(len & 0xFF));
        } else {
            buf.Write(uint8(0x80 | 127));
            for (int s = 56; s >= 0; s -= 8) {
                buf.Write(uint8((uint64(len) >> s) & 0xFF));
            }
        }

        uint32 key = uint32(Math::Rand(0, 0x7fffffff));
        uint8 mk0  = uint8((key >> 24) & 0xFF);
        uint8 mk1  = uint8((key >> 16) & 0xFF);
        uint8 mk2  = uint8((key >>  8) & 0xFF);
        uint8 mk3  = uint8( key        & 0xFF);
        buf.Write(mk0); buf.Write(mk1); buf.Write(mk2); buf.Write(mk3);

        for (uint i = 0; i < len; i++) {
            uint8 m = (i & 3) == 0 ? mk0 : (i & 3) == 1 ? mk1 : (i & 3) == 2 ? mk2 : mk3;
            buf.Write(uint8(payload[i]) ^ m);
        }

        buf.Seek(0);
        return buf.ReadString(buf.GetSize());
    }


    void ParseUrl(const string &in url) {
        secure         = url.StartsWith("wss://");
        uint prefixLen = secure ? 6 : 5;

        string remainder = url.SubStr(prefixLen);
        int    slashRel  = remainder.IndexOf("/");
        int    slashPos  = (slashRel < 0) ? -1 : prefixLen + slashRel;

        string authority = (slashPos < 0) ? remainder : url.SubStr(prefixLen, slashRel);

        int colonPos     = authority.IndexOf(":");

        host =       (colonPos < 0) ? authority : authority.SubStr(0, colonPos);
        port = uint16(colonPos < 0  ? (secure ? 443 : 80) : Text::ParseUInt(authority.SubStr(colonPos + 1)));
        path =       (slashPos < 0) ? "/"  : url.SubStr(slashPos);
    }

    void ScheduleReconnect() {
        Close();
        startnew(_Reconnect, @this);
    }
}

void _Reconnect(ref@ d) {
    WebSocketClient@ ws = cast<WebSocketClient>(d);
    sleep(3000);
    if (ws !is null) ws.Connect();
}
