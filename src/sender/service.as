namespace DataSender {
    namespace Sender {
        namespace Service {
            [Setting hidden name="Start service on plugin load"]
            bool S_AutoStart = false;

            bool g_initialized = false;
            bool g_running = false;
            uint g_startedAt = 0;
            uint g_stoppedAt = 0;
            uint g_updateCount = 0;
            string g_lastError = "";

            void Initialize() {
                if (g_initialized) return;

                g_initialized = true;
                DataSender::Sender::SourceRegistry::Initialize();
                DataSender::Sender::SourceRegistry::ResetScheduling(Time::Now);
                if (S_AutoStart) Start();
            }

            void Start() {
                Initialize();
                if (g_running) return;

                g_running = true;
                g_startedAt = Time::Now;
                g_stoppedAt = 0;
                g_lastError = "";
                DataSender::Sender::SourceRegistry::ResetScheduling(g_startedAt);
                DataSender::Server::Tcp::EnsureRunning();
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
                DataSender::Server::Tcp::Stop();
                g_initialized = false;
            }

            bool IsRunning() {
                return g_running;
            }

            string StatusText() {
                return g_running ? "Running" : "Stopped";
            }

            uint ConnectedClientCount() {
                return DataSender::Server::Tcp::ClientCount();
            }

            uint RaceDataSamples() {
                return DataSender::Sender::SourceRegistry::Samples("race_data");
            }

            uint VehicleStateSamples() {
                return DataSender::Sender::SourceRegistry::Samples("vehicle_state");
            }

            uint LastRaceDataAt() {
                DataSender::Sender::SourceRegistry::SourceState@ source = DataSender::Sender::SourceRegistry::GetById("race_data");
                return source is null ? 0 : source.lastSampleAt;
            }

            uint LastVehicleStateAt() {
                DataSender::Sender::SourceRegistry::SourceState@ source = DataSender::Sender::SourceRegistry::GetById("vehicle_state");
                return source is null ? 0 : source.lastSampleAt;
            }

            uint UpdateCount() {
                return g_updateCount;
            }

            uint StartedAt() {
                return g_startedAt;
            }

            uint StoppedAt() {
                return g_stoppedAt;
            }

            string LastError() {
                return g_lastError;
            }

            Json::Value GetLatestRaceData() {
                return DataSender::Sender::SourceRegistry::LatestData("race_data");
            }

            Json::Value GetLatestVehicleState() {
                return DataSender::Sender::SourceRegistry::LatestData("vehicle_state");
            }

            Json::Value GetLatestRaceDataMessage() {
                return DataSender::Sender::SourceRegistry::LatestMessage("race_data");
            }

            Json::Value GetLatestVehicleStateMessage() {
                return DataSender::Sender::SourceRegistry::LatestMessage("vehicle_state");
            }

            Json::Value LatestSourceMessages() {
                return DataSender::Sender::SourceRegistry::AllLatestMessages();
            }

            void Update(float dt) {
                if (!g_initialized) Initialize();

                if (g_running) {
                    g_updateCount++;
                    DataSender::Sender::SourceRegistry::Update(dt);
                }
                DataSender::Server::Tcp::Update(dt);
            }

            Json::Value StatusJson() {
                Json::Value root = Json::Object();
                root["running"] = g_running;
                root["startedAt"] = int(g_startedAt);
                root["stoppedAt"] = int(g_stoppedAt);
                root["updates"] = int(g_updateCount);
                root["clients"] = int(ConnectedClientCount());
                root["sourceSamples"] = int(DataSender::Sender::SourceRegistry::TotalSamples());
                root["raceDataSamples"] = int(RaceDataSamples());
                root["vehicleStateSamples"] = int(VehicleStateSamples());
                root["lastRaceDataAt"] = int(LastRaceDataAt());
                root["lastVehicleStateAt"] = int(LastVehicleStateAt());
                root["lastError"] = g_lastError;
                root["sources"] = DataSender::Sender::SourceRegistry::StatusJson();
                root["tcp"] = DataSender::Server::Tcp::StatusJson();
                return root;
            }

            Json::Value StatusMessage() {
                return DataSender::Shared::Messages::ServiceStatus(StatusJson(), Time::Now);
            }
        }
    }
}
