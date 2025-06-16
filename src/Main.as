const uint SEND_EVERY_MS = 1;

WebSocketClient@ wsFeed;
WebSocketClient@ wsVstate;
uint nextSend = 0;

void Main() {
    @wsFeed   = WebSocketClient("ws://127.0.0.1:8765/feed");
    @wsVstate = WebSocketClient("ws://127.0.0.1:8765/vstate");

    wsFeed.Connect();
    wsVstate.Connect();

    while (true) {
        wsFeed.Update();
        wsVstate.Update();

        if (Time::Now >= nextSend && wsFeed.state == WsState::Open && wsVstate.state == WsState::Open) {
            nextSend = Time::Now + SEND_EVERY_MS;

            wsFeed.SendText(Json::Write(MakeSnapshot(), false));
            wsVstate.SendText(Json::Write(VState::GetJson(),  false));
        }
        yield();
    }
}

void Update(float dt) {
    VState::Update(dt);
}

void OnDestroyed() {
    if (wsFeed   !is null) wsFeed.Close();
    if (wsVstate  !is null) wsVstate.Close();
}