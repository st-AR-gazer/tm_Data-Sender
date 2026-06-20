namespace DataSender {
    namespace Sender {
        namespace SourceRegistry {
            enum SourceKind {
                RaceData, PlayerCpInfo, VehicleState, Camera
            }

            [Setting hidden name="Enable race data source"]
            bool S_EnableRaceData = true;
            [Setting hidden name="Enable player CP info source"]
            bool S_EnablePlayerCpInfo = true;
            [Setting hidden name="Enable vehicle state source"]
            bool S_EnableVehicleState = true;
            [Setting hidden name="Enable camera source"]
            bool S_EnableCamera = false;
            [Setting hidden name="Race data interval" min=1 max=1000]
            uint S_RaceDataIntervalMs = 100;
            [Setting hidden name="Player CP info interval" min=1 max=1000]
            uint S_PlayerCpInfoIntervalMs = 1000;
            [Setting hidden name="Vehicle state interval" min=1 max=1000]
            uint S_VehicleStateIntervalMs = 16;
            [Setting hidden name="Camera interval" min=1 max=1000]
            uint S_CameraIntervalMs = 100;
            [Setting hidden name="Sample camera during render"]
            bool S_CameraSampleInRender = true;

            class SourceState {
                SourceKind kind;
                string id;
                string label;
                bool enabled;
                uint intervalMs;
                uint64 nextSampleAt;
                uint64 lastSampleAt;
                uint64 samples;
                uint64 errors;
                bool hasData;
                string lastError;
                Json::Value latestData;
                Json::Value latestMessage;

                SourceState(
                    SourceKind kind,
                    const string &in id,
                    const string &in label,
                    bool enabled,
                    uint intervalMs
                ) {
                    this.kind = kind;
                    this.id = id;
                    this.label = label;
                    this.enabled = enabled;
                    this.intervalMs = ClampInterval(intervalMs);
                    this.nextSampleAt = 0;
                    this.lastSampleAt = 0;
                    this.samples = 0;
                    this.errors = 0;
                    this.hasData = false;
                    this.lastError = "";
                    this.latestData = Json::Object();
                    this.latestMessage = Json::Object();
                }
            }

            bool g_initialized = false;
            array<SourceState@> g_sources;
            SourceState@ g_raceDataSource;
            SourceState@ g_playerCpInfoSource;
            SourceState@ g_vehicleStateSource;
            SourceState@ g_cameraSource;

            void Initialize() {
                if (g_initialized) return;

                g_initialized = true;
                g_sources.RemoveRange(0, g_sources.Length);
                @g_raceDataSource = SourceState(
                    SourceKind::RaceData,
                    "race_data",
                    "Race data",
                    S_EnableRaceData,
                    S_RaceDataIntervalMs
                );
                @g_playerCpInfoSource = SourceState(
                    SourceKind::PlayerCpInfo,
                    "player_cp_info",
                    "Player CP info",
                    S_EnablePlayerCpInfo,
                    S_PlayerCpInfoIntervalMs
                );
                @g_vehicleStateSource = SourceState(
                    SourceKind::VehicleState,
                    "vehicle_state",
                    "Vehicle state",
                    S_EnableVehicleState,
                    S_VehicleStateIntervalMs
                );
                @g_cameraSource = SourceState(
                    SourceKind::Camera,
                    "camera",
                    "Camera",
                    S_EnableCamera,
                    S_CameraIntervalMs
                );
                g_sources.InsertLast(g_raceDataSource);
                g_sources.InsertLast(g_playerCpInfoSource);
                g_sources.InsertLast(g_vehicleStateSource);
                g_sources.InsertLast(g_cameraSource);
                ApplySettings();
                ResetScheduling(Time::Now);
            }

            void ResetScheduling(uint64 now) {
                Initialize();
                for (uint i = 0; i < g_sources.Length; i++) {
                    g_sources[i].nextSampleAt = now;
                }
            }

            void Update(float dt) {
                Initialize();
                ApplySettings();
                uint64 now = Time::Now;
                for (uint i = 0; i < g_sources.Length; i++) {
                    SourceState@ source = g_sources[i];
                    if (!source.enabled) continue;
                    if (source.kind == SourceKind::Camera && S_CameraSampleInRender) continue;
                    if (now < source.nextSampleAt) continue;
                    if (!DataSender::Server::Tcp::HasTelemetryDemandForSource(source.id)) continue;

                    Poll(source, dt, now);
                }
            }

            void Render() {
                Initialize();
                if (!S_CameraSampleInRender) return;
                if (DataSender::Server::Tcp::ClientCount() == 0) return;

                SourceState@ camera = g_cameraSource;
                if (camera is null) return;
                if (!camera.enabled) return;

                uint64 now = Time::Now;
                if (now < camera.nextSampleAt) return;
                if (!DataSender::Server::Tcp::HasTelemetryDemandForSource(camera.id)) return;
                Poll(camera, 0.0, now);
            }

            uint Count() {
                Initialize();
                return g_sources.Length;
            }

            SourceState@ Get(uint index) {
                Initialize();
                if (index >= g_sources.Length) return null;
                return g_sources[index];
            }

            SourceState@ GetById(const string &in id) {
                Initialize();
                for (uint i = 0; i < g_sources.Length; i++) {
                    if (g_sources[i].id == id) return g_sources[i];
                }
                return null;
            }

            bool IsEnabled(const string &in id) {
                SourceState@ source = GetById(id);
                return source !is null && source.enabled;
            }

            bool SetEnabled(const string &in id, bool enabled) {
                SourceState@ source = GetById(id);
                if (source is null) return false;

                bool wasEnabled = source.enabled;
                if (id == "race_data") {
                    S_EnableRaceData = enabled;
                } else if (id == "player_cp_info") {
                    S_EnablePlayerCpInfo = enabled;
                } else if (id == "vehicle_state") {
                    S_EnableVehicleState = enabled;
                } else if (id == "camera") {
                    S_EnableCamera = enabled;
                } else {
                    return false;
                }
                ApplySettings();
                if (!enabled) {
                    ClearLatest(source);
                } else if (!wasEnabled) {
                    source.nextSampleAt = Time::Now;
                }
                return true;
            }

            uint IntervalMs(const string &in id) {
                SourceState@ source = GetById(id);
                return source is null ? 0 : source.intervalMs;
            }

            bool SetIntervalMs(const string &in id, uint intervalMs) {
                intervalMs = ClampInterval(intervalMs);
                if (id == "race_data") {
                    S_RaceDataIntervalMs = intervalMs;
                } else if (id == "player_cp_info") {
                    S_PlayerCpInfoIntervalMs = intervalMs;
                } else if (id == "vehicle_state") {
                    S_VehicleStateIntervalMs = intervalMs;
                } else if (id == "camera") {
                    S_CameraIntervalMs = intervalMs;
                } else {
                    return false;
                }
                ApplySettings();
                return true;
            }

            uint64 Samples(const string &in id) {
                SourceState@ source = GetById(id);
                return source is null ? 0 : source.samples;
            }

            uint64 TotalSamples() {
                Initialize();
                uint64 total = 0;
                for (uint i = 0; i < g_sources.Length; i++) {
                    total += g_sources[i].samples;
                }
                return total;
            }

            Json::Value LatestData(const string &in id) {
                SourceState@ source = GetById(id);
                if (source is null || !source.enabled || !source.hasData) return Json::Object();
                return source.latestData;
            }

            Json::Value LatestMessage(const string &in id) {
                SourceState@ source = GetById(id);
                if (source is null || !source.enabled || !source.hasData) return Json::Object();
                return source.latestMessage;
            }

            Json::Value Latest(const string &in id) {
                return LatestMessage(id);
            }

            Json::Value AllLatestMessages() {
                Initialize();
                Json::Value messages = Json::Array();
                for (uint i = 0; i < g_sources.Length; i++) {
                    SourceState@ source = g_sources[i];
                    if (!source.enabled || !source.hasData) continue;
                    messages.Add(source.latestMessage);
                }
                return messages;
            }

            Json::Value StatusJson() {
                Initialize();
                Json::Value sources = Json::Array();
                for (uint i = 0; i < g_sources.Length; i++) {
                    SourceState@ source = g_sources[i];
                    sources.Add(SourceStatusJson(source));
                }
                return sources;
            }

            Json::Value SourceStatusJson(SourceState@ source) {
                Json::Value item = Json::Object();
                if (source is null) return item;

                item["id"] = source.id;
                item["label"] = source.label;
                item["enabled"] = source.enabled;
                item["requested"] = DataSender::Server::Tcp::HasTelemetryDemandForSource(source.id);
                item["intervalMs"] = int(source.intervalMs);
                item["samples"] = DataSender::Toolkit::JsonCounter(source.samples);
                item["errors"] = DataSender::Toolkit::JsonCounter(source.errors);
                item["lastSampleAt"] = DataSender::Toolkit::JsonTime(source.lastSampleAt);
                item["hasData"] = source.hasData;
                item["lastError"] = source.lastError;
                return item;
            }

            Json::Value SourceStatusJson(const string &in id) {
                return SourceStatusJson(GetById(id));
            }

            uint ClampInterval(uint value) {
                if (value < 1) return 1;
                if (value > 1000) return 1000;
                return value;
            }

            void ApplySettings() {
                if (g_raceDataSource !is null) {
                    g_raceDataSource.enabled = S_EnableRaceData;
                    g_raceDataSource.intervalMs = ClampInterval(S_RaceDataIntervalMs);
                }
                if (g_playerCpInfoSource !is null) {
                    g_playerCpInfoSource.enabled = S_EnablePlayerCpInfo;
                    g_playerCpInfoSource.intervalMs = ClampInterval(S_PlayerCpInfoIntervalMs);
                }
                if (g_vehicleStateSource !is null) {
                    g_vehicleStateSource.enabled = S_EnableVehicleState;
                    g_vehicleStateSource.intervalMs = ClampInterval(S_VehicleStateIntervalMs);
                }
                if (g_cameraSource !is null) {
                    g_cameraSource.enabled = S_EnableCamera;
                    g_cameraSource.intervalMs = ClampInterval(S_CameraIntervalMs);
                }
            }

            void ClearLatest(SourceState@ source) {
                if (source is null) return;

                source.hasData = false;
                source.latestData = Json::Object();
                source.latestMessage = Json::Object();
                source.lastError = "";
            }

            void Poll(SourceState@ source, float dt, uint64 now) {
                if (source is null) return;

                Json::Value data = Json::Object();
                string error = "";
                try {
                    data = ReadSource(source.kind, dt);
                } catch {
                    error = getExceptionInfo();
                    if (error.Length == 0) error = "unknown source exception";
                    error = DataSender::Toolkit::Truncate(error, 512);
                    data = SourceErrorJson(error);
                    source.errors++;
                    log(
                        "Source poll failed for " + source.id + ": " + error,
                        LogLevel::Warning,
                        340,
                        "DataSender::Sender::SourceRegistry::Poll"
                    );
                }
                source.latestData = data;
                source.hasData = true;
                source.lastSampleAt = now;
                source.samples++;
                source.latestMessage = DataSender::Shared::Messages::Snapshot(
                    source.id,
                    source.label,
                    source.latestData,
                    now,
                    source.samples
                );
                source.nextSampleAt = now + ClampInterval(source.intervalMs);
                source.lastError = error;
            }

            Json::Value SourceErrorJson(const string &in error) {
                Json::Value root = Json::Object();
                root["available"] = false;
                root["reason"] = "source_error";
                root["error"] = error;
                return root;
            }

            Json::Value ReadSource(SourceKind kind, float dt) {
                if (kind == SourceKind::RaceData) {
                    return DataSender::Sources::MLFeedRaceDataSource::MakeSnapshot();
                }
                if (kind == SourceKind::PlayerCpInfo) {
                    return DataSender::Sources::MLFeedCpInfoSource::MakeSnapshot();
                }
                if (kind == SourceKind::VehicleState) {
                    DataSender::Sources::VehicleStateSource::Update(dt);
                    return DataSender::Sources::VehicleStateSource::GetJson();
                }
                if (kind == SourceKind::Camera) {
                    return DataSender::Sources::CameraSource::GetJson();
                }
                return Json::Object();
            }
        }
    }
}
