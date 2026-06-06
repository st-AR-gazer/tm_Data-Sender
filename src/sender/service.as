namespace DataSender {
namespace Sender {
namespace Service {
    [Setting hidden name="Start service on plugin load"]
    bool S_AutoStart = false;

    [Setting hidden name="Enable race data source"]
    bool S_EnableRaceData = true;

    [Setting hidden name="Enable vehicle state source"]
    bool S_EnableVehicleState = true;

    [Setting hidden name="Race data interval" min=1 max=1000]
    uint S_RaceDataIntervalMs = 100;

    [Setting hidden name="Vehicle state interval" min=1 max=1000]
    uint S_VehicleStateIntervalMs = 16;

    bool g_initialized = false;
    bool g_running = false;

    uint g_startedAt = 0;
    uint g_stoppedAt = 0;
    uint g_updateCount = 0;

    uint g_nextRaceDataAt = 0;
    uint g_nextVehicleStateAt = 0;

    uint g_lastRaceDataAt = 0;
    uint g_lastVehicleStateAt = 0;

    uint g_raceDataSamples = 0;
    uint g_vehicleStateSamples = 0;

    string g_lastError = "";

    Json::Value g_latestRaceData;
    Json::Value g_latestVehicleState;

    void Initialize() {
        if (g_initialized) return;

        g_initialized = true;
        ResetScheduling(Time::Now);

        if (S_AutoStart) Start();
    }

    void Start() {
        Initialize();
        if (g_running) return;

        g_running = true;
        g_startedAt = Time::Now;
        g_lastError = "";
        ResetScheduling(g_startedAt);

        log("Service started", LogLevel::Info, 46, "Service::Start");
    }

    void Stop() {
        if (!g_running) return;

        g_running = false;
        g_stoppedAt = Time::Now;

        log("Service stopped", LogLevel::Info, 57, "Service::Stop");
    }

    void Shutdown() {
        Stop();
        g_initialized = false;
    }

    bool IsRunning() {
        return g_running;
    }

    string StatusText() {
        return g_running ? "Running" : "Stopped";
    }

    uint ConnectedClientCount() {
        return 0;
    }

    uint RaceDataSamples() {
        return g_raceDataSamples;
    }

    uint VehicleStateSamples() {
        return g_vehicleStateSamples;
    }

    uint LastRaceDataAt() {
        return g_lastRaceDataAt;
    }

    uint LastVehicleStateAt() {
        return g_lastVehicleStateAt;
    }

    uint UpdateCount() {
        return g_updateCount;
    }

    string LastError() {
        return g_lastError;
    }

    Json::Value GetLatestRaceData() {
        return g_latestRaceData;
    }

    Json::Value GetLatestVehicleState() {
        return g_latestVehicleState;
    }

    void Update(float dt) {
        if (!g_initialized) Initialize();
        if (!g_running) return;

        g_updateCount++;

        uint now = Time::Now;
        if (S_EnableVehicleState && now >= g_nextVehicleStateAt) {
            PollVehicleState(dt, now);
        }

        if (S_EnableRaceData && now >= g_nextRaceDataAt) {
            PollRaceData(now);
        }
    }

    Json::Value StatusJson() {
        Json::Value root = Json::Object();
        root["running"] = g_running;
        root["startedAt"] = int(g_startedAt);
        root["stoppedAt"] = int(g_stoppedAt);
        root["updates"] = int(g_updateCount);
        root["clients"] = int(ConnectedClientCount());
        root["raceDataSamples"] = int(g_raceDataSamples);
        root["vehicleStateSamples"] = int(g_vehicleStateSamples);
        root["lastRaceDataAt"] = int(g_lastRaceDataAt);
        root["lastVehicleStateAt"] = int(g_lastVehicleStateAt);
        root["lastError"] = g_lastError;
        return root;
    }

    uint ClampInterval(uint value) {
        return value < 1 ? 1 : value;
    }

    void ResetScheduling(uint now) {
        g_nextRaceDataAt = now;
        g_nextVehicleStateAt = now;
    }

    void PollRaceData(uint now) {
        g_latestRaceData = DataSender::Sources::RaceData::MakeSnapshot();
        g_lastRaceDataAt = now;
        g_raceDataSamples++;
        g_nextRaceDataAt = now + ClampInterval(S_RaceDataIntervalMs);
    }

    void PollVehicleState(float dt, uint now) {
        DataSender::Sources::VehicleStateSource::Update(dt);
        g_latestVehicleState = DataSender::Sources::VehicleStateSource::GetJson();
        g_lastVehicleStateAt = now;
        g_vehicleStateSamples++;
        g_nextVehicleStateAt = now + ClampInterval(S_VehicleStateIntervalMs);
    }
}
}
}
