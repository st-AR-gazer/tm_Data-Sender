namespace DataSender {
    namespace Sender {
        namespace Service {
            [Setting hidden name="Start service on plugin load"]
            bool S_AutoStart = false;

            bool g_initialized = false;
            bool g_running = false;
            uint64 g_startedAt = 0;
            uint64 g_stoppedAt = 0;
            uint64 g_updateCount = 0;
            uint64 g_updateErrors = 0;
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
                log("Service started", LogLevel::Info, 34, "DataSender::Sender::Service::Start");
            }

            void Stop() {
                if (!g_running) return;

                g_running = false;
                g_stoppedAt = Time::Now;
                log("Service stopped", LogLevel::Info, 42, "DataSender::Sender::Service::Stop");
            }

            void Shutdown() {
                Stop();
                DataSender::Server::Tcp::Stop();
                g_initialized = false;
            }

            bool IsRunning() {
                return g_running;
            }

            uint ConnectedClientCount() {
                return DataSender::Server::Tcp::ClientCount();
            }

            uint64 UpdateCount() {
                return g_updateCount;
            }

            uint64 StartedAt() {
                return g_startedAt;
            }

            uint64 StoppedAt() {
                return g_stoppedAt;
            }

            uint64 UpdateErrors() {
                return g_updateErrors;
            }

            string LastError() {
                return g_lastError;
            }

            Json::Value LatestSourceMessages() {
                return DataSender::Sender::SourceRegistry::AllLatestMessages();
            }

            void Update(float dt) {
                try {
                    UpdateInner(dt);
                } catch {
                    g_updateErrors++;
                    g_lastError = DataSender::Toolkit::Truncate(getExceptionInfo(), 512);
                    if (g_lastError.Length == 0) g_lastError = "unknown service update exception";
                    log("Service update failed: " + g_lastError, LogLevel::Warning, 90, "DataSender::Sender::Service::Update");
                }
            }

            void Render() {
                try {
                    RenderInner();
                } catch {
                    g_updateErrors++;
                    g_lastError = DataSender::Toolkit::Truncate(getExceptionInfo(), 512);
                    if (g_lastError.Length == 0) g_lastError = "unknown service render exception";
                    log("Service render failed: " + g_lastError, LogLevel::Warning, 102, "DataSender::Sender::Service::Render");
                }
            }

            void UpdateInner(float dt) {
                if (!g_initialized) Initialize();

                if (g_running) {
                    g_updateCount++;
                    DataSender::Sender::SourceRegistry::Update(dt);
                }
                DataSender::Server::Tcp::Update(dt);
            }

            void RenderInner() {
                if (!g_initialized) Initialize();
                if (!g_running) return;

                DataSender::Sender::SourceRegistry::Render();
            }

            Json::Value StatusJson() {
                Json::Value root = Json::Object();
                root["running"] = g_running;
                root["startedAt"] = DataSender::Toolkit::JsonTime(g_startedAt);
                root["stoppedAt"] = DataSender::Toolkit::JsonTime(g_stoppedAt);
                root["updates"] = DataSender::Toolkit::JsonCounter(g_updateCount);
                root["updateErrors"] = DataSender::Toolkit::JsonCounter(g_updateErrors);
                root["clients"] = int(ConnectedClientCount());
                root["sourceSamples"] = DataSender::Toolkit::JsonCounter(DataSender::Sender::SourceRegistry::TotalSamples());
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
