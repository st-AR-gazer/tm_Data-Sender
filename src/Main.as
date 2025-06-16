[Setting name="send threshold" min=1 max=1000 hidden] uint SEND_EVERY_MS = 1;
[Setting name="port" hidden] int PORT = 8765;
[Setting name="Automatic startup on plugin load" hidden] bool AutoStart = false;

[SettingsTab name="General" icon="Cog" order="1"]
void RT_Settings() {
    if (UI::BeginChild("General Settings", vec2(0, 0), true)) {

        SEND_EVERY_MS = UI::SliderInt("Send every (ms)", SEND_EVERY_MS, 1, 1000);
        PORT = UI::SliderInt("Port", PORT, 1, 65535);
        
        if (UI::Button("restart server + connect")) {
            if (wsFeed !is null) wsFeed.Close();
            if (wsVstate !is null) wsVstate.Close();
            startnew(Main);
        }
        UI::SameLine();

        if (wsFeed !is null && wsVstate !is null && (wsFeed.state != WsState::Open || wsVstate.state != WsState::Open)) {
            if (UI::Button("reconnect")) {
                wsFeed.Connect();
                wsVstate.Connect();
            }
        } else if (wsFeed is null || wsVstate is null) {
            if (UI::Button("connect")) {
                startnew(Main);
            }
        } else {
            _UI::DisabledButton("(re)connect");
        }
        
        UI::SameLine();
        if (UI::Button("disconnect")) {
            if (wsFeed !is null) wsFeed.Close();
            if (wsVstate !is null) wsVstate.Close();
        }

        AutoStart = UI::Checkbox("Automatic startup on plugin load", AutoStart);

        UI::Separator();

        

        if (UI::Button("Reset to defaults")) {
            SEND_EVERY_MS = 1;
            PORT = 8765;
        }

        UI::EndChild();
    }
}

WebSocketClient@ wsFeed;
WebSocketClient@ wsVstate;
uint nextSend = 0;

void Main() {
    if (AutoStart) {
        if (wsFeed   !is null) wsFeed.Close();
        if (wsVstate !is null) wsVstate.Close();
    } else {
        return;
    }

    @wsFeed   = WebSocketClient("ws://127.0.0.1:"+PORT+"/feed");
    @wsVstate = WebSocketClient("ws://127.0.0.1:"+PORT+"/vstate");

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