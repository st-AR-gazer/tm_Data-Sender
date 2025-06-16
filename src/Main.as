const uint SEND_EVERY_MS = 100;

WebSocketClient@ ws;
uint nextSend = 0;

void Main() {
    @ws = WebSocketClient("ws://127.0.0.1:8765/feed");
    ws.Connect();

    while (true) {
        ws.Update();

        if (Time::Now >= nextSend && ws.state == State::Open) {
            nextSend = Time::Now + SEND_EVERY_MS;

            Json::Value snap = MakeSnapshot();
            ws.SendText(Json::Write(snap, false));
        }
        yield();
    }
}

void Update(float dt) {
    VState::Update(dt);
}

void Render() {
    auto vjson = VState::GetJson();
    
    UI::Begin("RaceData-WS");
    UI::Text("Socket: " + tostring(ws.state));
    UI::Text("Last: " + Time::Format(Time::Now - VState::g_latest.t, true, true));
    UI::Text("Speed: " + tostring(float(vjson["spd"])) + " m/s");
    UI::Text("Accel: " + tostring(float(vjson["accel"])) + " m/s^2");
    UI::Text("Jerk: " + tostring(float(vjson["jerk"])) + " m/s^3");
    UI::Text("Steer: " + tostring(float(vjson["steer"])));
    UI::End();
}

void OnDestroyed() {
    if (ws !is null) ws.Close();
}
