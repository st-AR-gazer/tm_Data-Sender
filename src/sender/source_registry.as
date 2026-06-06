namespace DataSender {
    namespace Sender {
        namespace SourceRegistry {
            enum SourceKind {
                RaceData, VehicleState, Camera, ServerInfo
            }

            [Setting hidden name="Enable race data source"]
            bool S_EnableRaceData = true;
            [Setting hidden name="Enable vehicle state source"]
            bool S_EnableVehicleState = true;
            [Setting hidden name="Enable camera source"]
            bool S_EnableCamera = false;
            [Setting hidden name="Enable server info source"]
            bool S_EnableServerInfo = false;
            [Setting hidden name="Race data interval" min=1 max=1000]
            uint S_RaceDataIntervalMs = 100;
            [Setting hidden name="Vehicle state interval" min=1 max=1000]
            uint S_VehicleStateIntervalMs = 16;
            [Setting hidden name="Camera interval" min=1 max=1000]
            uint S_CameraIntervalMs = 100;
            [Setting hidden name="Server info interval" min=1 max=1000]
            uint S_ServerInfoIntervalMs = 1000;

            class SourceState {
                SourceKind kind;
                string id;
                string label;
                bool enabled;
                uint intervalMs;
                uint nextSampleAt;
                uint lastSampleAt;
                uint samples;
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
                    this.hasData = false;
                    this.lastError = "";
                    this.latestData = Json::Object();
                    this.latestMessage = Json::Object();
                }
            }

            bool g_initialized = false;
            array<SourceState@> g_sources;

            void Initialize() {
                if (g_initialized) return;

                g_initialized = true;
                g_sources.RemoveRange(0, g_sources.Length);
                g_sources.InsertLast(SourceState(SourceKind::RaceData, "race_data", "Race data", S_EnableRaceData, S_RaceDataIntervalMs));
                g_sources.InsertLast(SourceState(SourceKind::VehicleState, "vehicle_state", "Vehicle state", S_EnableVehicleState, S_VehicleStateIntervalMs));
                g_sources.InsertLast(SourceState(SourceKind::Camera, "camera", "Camera", S_EnableCamera, S_CameraIntervalMs));
                g_sources.InsertLast(SourceState(SourceKind::ServerInfo, "server_info", "Server info", S_EnableServerInfo, S_ServerInfoIntervalMs));
                ApplySettings();
                ResetScheduling(Time::Now);
            }

            void ResetScheduling(uint now) {
                Initialize();
                for (uint i = 0; i < g_sources.Length; i++) {
                    g_sources[i].nextSampleAt = now;
                }
            }

            void Update(float dt) {
                Initialize();
                ApplySettings();
                uint now = Time::Now;
                for (uint i = 0; i < g_sources.Length; i++) {
                    SourceState@ source = g_sources[i];
                    if (!source.enabled) continue;
                    if (now < source.nextSampleAt) continue;

                    Poll(source, dt, now);
                }
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
                if (id == "race_data") {
                    S_EnableRaceData = enabled;
                } else if (id == "vehicle_state") {
                    S_EnableVehicleState = enabled;
                } else if (id == "camera") {
                    S_EnableCamera = enabled;
                } else if (id == "server_info") {
                    S_EnableServerInfo = enabled;
                } else {
                    return false;
                }
                ApplySettings();
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
                } else if (id == "vehicle_state") {
                    S_VehicleStateIntervalMs = intervalMs;
                } else if (id == "camera") {
                    S_CameraIntervalMs = intervalMs;
                } else if (id == "server_info") {
                    S_ServerInfoIntervalMs = intervalMs;
                } else {
                    return false;
                }
                ApplySettings();
                return true;
            }

            uint Samples(const string &in id) {
                SourceState@ source = GetById(id);
                return source is null ? 0 : source.samples;
            }

            uint TotalSamples() {
                Initialize();
                uint total = 0;
                for (uint i = 0; i < g_sources.Length; i++) {
                    total += g_sources[i].samples;
                }
                return total;
            }

            Json::Value LatestData(const string &in id) {
                SourceState@ source = GetById(id);
                if (source is null) return Json::Object();
                return source.latestData;
            }

            Json::Value LatestMessage(const string &in id) {
                SourceState@ source = GetById(id);
                if (source is null) return Json::Object();
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
                    if (!source.hasData) continue;
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
                item["intervalMs"] = int(source.intervalMs);
                item["samples"] = int(source.samples);
                item["lastSampleAt"] = int(source.lastSampleAt);
                item["hasData"] = source.hasData;
                item["lastError"] = source.lastError;
                return item;
            }

            Json::Value SourceStatusJson(const string &in id) {
                return SourceStatusJson(GetById(id));
            }

            uint ClampInterval(uint value) {
                return value < 1 ? 1 : value;
            }

            void ApplySettings() {
                SourceState@ raceData = GetById("race_data");
                if (raceData !is null) {
                    raceData.enabled = S_EnableRaceData;
                    raceData.intervalMs = ClampInterval(S_RaceDataIntervalMs);
                }
                SourceState@ vehicleState = GetById("vehicle_state");
                if (vehicleState !is null) {
                    vehicleState.enabled = S_EnableVehicleState;
                    vehicleState.intervalMs = ClampInterval(S_VehicleStateIntervalMs);
                }
                SourceState@ camera = GetById("camera");
                if (camera !is null) {
                    camera.enabled = S_EnableCamera;
                    camera.intervalMs = ClampInterval(S_CameraIntervalMs);
                }
                SourceState@ serverInfo = GetById("server_info");
                if (serverInfo !is null) {
                    serverInfo.enabled = S_EnableServerInfo;
                    serverInfo.intervalMs = ClampInterval(S_ServerInfoIntervalMs);
                }
            }

            void Poll(SourceState@ source, float dt, uint now) {
                source.latestData = ReadSource(source.kind, dt);
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
                source.lastError = "";
            }

            Json::Value ReadSource(SourceKind kind, float dt) {
                if (kind == SourceKind::RaceData) {
                    return DataSender::Sources::RaceData::MakeSnapshot();
                }
                if (kind == SourceKind::VehicleState) {
                    DataSender::Sources::VehicleStateSource::Update(dt);
                    return DataSender::Sources::VehicleStateSource::GetJson();
                }
                if (kind == SourceKind::Camera) {
                    DataSender::Sources::Camera::Update(dt);
                    return DataSender::Sources::Camera::GetJson();
                }
                if (kind == SourceKind::ServerInfo) {
                    return DataSender::Sources::ServerInfo::GetJson();
                }
                return Json::Object();
            }
        }
    }
}
