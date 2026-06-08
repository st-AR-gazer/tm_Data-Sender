namespace DataSender {
    namespace Server {
        namespace Tcp {
            Net::Socket@ g_listener;
            array<ClientSession@> g_clients;
            bool g_running = false;
            string g_boundHost = "";
            uint16 g_boundPort = 0;
            string g_lastError = "";
            uint64 g_lastBroadcastAt = 0;
            uint64 g_nextStartAttemptAt = 0;
            uint64 g_totalAccepted = 0;
            uint64 g_totalRejected = 0;
            uint64 g_totalDisconnected = 0;
            uint64 g_totalMessagesSent = 0;
            uint64 g_totalTelemetryDropped = 0;
            uint64 g_updateErrors = 0;

            bool IsRunning() {
                return g_running;
            }

            string StatusText() {
                if (!S_Enabled) return "Disabled";
                return g_running ? "Listening" : "Stopped";
            }

            string AddressText() {
                return ConfiguredHost() + ":" + tostring(ConfiguredPort());
            }

            string LastError() {
                return g_lastError;
            }

            uint ClientCount() {
                return g_clients.Length;
            }

            uint64 TotalAccepted() {
                return g_totalAccepted;
            }

            uint64 TotalRejected() {
                return g_totalRejected;
            }

            uint64 TotalDisconnected() {
                return g_totalDisconnected;
            }

            uint64 TotalMessagesSent() {
                return g_totalMessagesSent;
            }

            uint64 TotalTelemetryDropped() {
                return g_totalTelemetryDropped;
            }

            uint64 UpdateErrors() {
                return g_updateErrors;
            }

            ClientSession@ GetClient(uint index) {
                if (index >= g_clients.Length) return null;
                return g_clients[index];
            }

            void DisconnectClient(uint index) {
                CloseClientAt(index);
            }

            void EnsureRunning() {
                if (!S_Enabled) {
                    if (g_running) Stop();
                    return;
                }

                string host = ConfiguredHost();
                uint16 port = ConfiguredPort();
                if (g_running && (g_boundHost != host || g_boundPort != port)) {
                    Stop();
                }
                if (!g_running && Time::Now >= g_nextStartAttemptAt) {
                    Start();
                }
            }

            bool Start() {
                if (!S_Enabled) return false;
                if (g_running) return true;

                string host = ConfiguredHost();
                uint16 port = ConfiguredPort();
                @g_listener = Net::Socket();
                bool listening = false;
                try {
                    listening = g_listener.Listen(host, port);
                } catch {
                    g_lastError = "Could not listen on " + host + ":" + tostring(port) + ": " + DataSender::Toolkit::Truncate(
                        getExceptionInfo(),
                        512
                    );
                }

                if (!listening) {
                    if (g_lastError.Length == 0) {
                        g_lastError = "Could not listen on " + host + ":" + tostring(port);
                    }
                    g_nextStartAttemptAt = Time::Now + StartRetryMs();
                    @g_listener = null;
                    log(
                        g_lastError,
                        LogLevel::Warning,
                        112,
                        "DataSender::Server::Tcp::Start"
                    );
                    return false;
                }

                g_running = true;
                g_boundHost = host;
                g_boundPort = port;
                g_lastError = "";
                g_nextStartAttemptAt = 0;
                g_lastBroadcastAt = 0;
                log(
                    "TCP server listening on " + g_boundHost + ":" + tostring(g_boundPort),
                    LogLevel::Info,
                    127,
                    "DataSender::Server::Tcp::Start"
                );
                return true;
            }

            void Stop() {
                CloseClients();
                if (g_listener !is null) {
                    try {
                        g_listener.Close();
                    } catch {
                        RecordError("TCP listener close failed: " + getExceptionInfo(), 102, "Tcp::Stop");
                    }
                    @g_listener = null;
                }
                if (g_running) {
                    log(
                        "TCP server stopped",
                        LogLevel::Info,
                        147,
                        "DataSender::Server::Tcp::Stop"
                    );
                }
                g_running = false;
                g_boundHost = "";
                g_boundPort = 0;
            }

            void Update(float dt) {
                try {
                    UpdateInner(dt);
                } catch {
                    g_updateErrors++;
                    RecordError("TCP update failed: " + getExceptionInfo(), 130, "Tcp::Update");
                    Stop();
                    g_nextStartAttemptAt = Time::Now + StartRetryMs();
                }
            }

            void UpdateInner(float dt) {
                EnsureRunning();
                if (!g_running) return;

                bool telemetryRunningAtStart = DataSender::Sender::Service::IsRunning();
                AcceptClients();
                UpdateClients();
                if (!telemetryRunningAtStart || !DataSender::Sender::Service::IsRunning()) return;

                uint64 now = Time::Now;
                uint intervalMs = BroadcastIntervalMs();
                if (intervalMs == 0 || now >= g_lastBroadcastAt + intervalMs) {
                    g_lastBroadcastAt = now;
                    BroadcastTelemetry();
                }
            }

            Json::Value StatusJson() {
                Json::Value root = Json::Object();
                root["enabled"] = S_Enabled;
                root["running"] = g_running;
                root["host"] = ConfiguredHost();
                root["port"] = int(ConfiguredPort());
                root["clients"] = int(ClientCount());
                root["maxClients"] = S_MaxClients;
                root["totalAccepted"] = DataSender::Toolkit::JsonCounter(g_totalAccepted);
                root["totalRejected"] = DataSender::Toolkit::JsonCounter(g_totalRejected);
                root["totalDisconnected"] = DataSender::Toolkit::JsonCounter(g_totalDisconnected);
                root["messagesSent"] = DataSender::Toolkit::JsonCounter(g_totalMessagesSent);
                root["telemetryDropped"] = DataSender::Toolkit::JsonCounter(g_totalTelemetryDropped);
                root["maxTelemetryMessagesPerSecond"] = int(MaxTelemetryMessagesPerSecond());
                root["updateErrors"] = DataSender::Toolkit::JsonCounter(g_updateErrors);
                root["lastError"] = g_lastError;
                return root;
            }

            void AcceptClients() {
                if (g_listener is null) return;

                for (uint i = 0; i < AcceptsPerUpdate(); i++) {
                    Net::Socket@ socket = null;
                    try {
                        @socket = g_listener.Accept();
                    } catch {
                        g_updateErrors++;
                        RecordError("TCP accept failed: " + getExceptionInfo(), 175, "Tcp::AcceptClients");
                        Stop();
                        return;
                    }
                    if (socket is null) break;

                    if (g_clients.Length >= MaxClients()) {
                        g_totalRejected++;
                        SendErrorAndClose(socket, "max_clients", "DataSender TCP server is full");
                        continue;
                    }

                    ClientSession@ client = ClientSession(socket, Time::Now);
                    g_clients.InsertLast(client);
                    g_totalAccepted++;
                    SendToClient(client, DataSender::Sender::Service::StatusMessage());
                    log(
                        "TCP client connected",
                        LogLevel::Info,
                        231,
                        "DataSender::Server::Tcp::AcceptClients"
                    );
                }
            }

            void UpdateClients() {
                uint64 now = Time::Now;
                for (int i = int(g_clients.Length) - 1; i >= 0; i--) {
                    ClientSession@ client = g_clients[uint(i)];
                    if (client is null || !client.IsAlive(now)) {
                        CloseClientAt(uint(i));
                        continue;
                    }
                    if (!client.DrainIncoming(now)) {
                        CloseClientAt(uint(i));
                    }
                }
            }

            void BroadcastTelemetry() {
                BroadcastTelemetryMessage(DataSender::Sender::Service::StatusMessage());
                Json::Value messages = DataSender::Sender::Service::LatestSourceMessages();

                for (uint i = 0; i < messages.Length; i++) {
                    BroadcastSourceMessage(messages[i]);
                }
            }

            void BroadcastTelemetryMessage(const Json::Value &in message) {
                for (int i = int(g_clients.Length) - 1; i >= 0; i--) {
                    ClientSession@ client = g_clients[uint(i)];
                    if (!SendTelemetryToClient(client, message)) {
                        CloseClientAt(uint(i));
                    }
                }
            }

            void SendLatestMessages(ClientSession@ client) {
                Json::Value messages = DataSender::Sender::Service::LatestSourceMessages();
                for (uint i = 0; i < messages.Length; i++) {
                    if (!ShouldSendToClient(client, messages[i])) continue;
                    if (!SendTelemetryToClient(client, messages[i])) return;
                }
            }

            void BroadcastSourceMessage(const Json::Value &in message) {
                for (int i = int(g_clients.Length) - 1; i >= 0; i--) {
                    ClientSession@ client = g_clients[uint(i)];
                    if (!ShouldSendToClient(client, message)) continue;

                    if (!SendTelemetryToClient(client, message)) {
                        CloseClientAt(uint(i));
                    }
                }
            }

            bool ShouldSendToClient(ClientSession@ client, const Json::Value &in message) {
                if (client is null) return false;
                string sourceId = MessageSourceId(message);
                if (sourceId.Length == 0 || sourceId == "service") return true;
                if (!client.IsSubscribedTo(sourceId)) return false;

                uint64 seq = MessageSeq(message);
                if (client.HasSentSourceSeq(sourceId, seq)) return false;
                return true;
            }

            bool SendTelemetryToClient(ClientSession@ client, const Json::Value &in message) {
                if (client is null) return false;
                if (!client.TryConsumeTelemetrySlot()) {
                    g_totalTelemetryDropped++;
                    return true;
                }
                return SendToClient(client, message);
            }

            bool SendToClient(ClientSession@ client, const Json::Value &in message) {
                if (client is null) return false;
                bool ok = client.SendJson(message);
                if (ok) {
                    g_totalMessagesSent++;
                    MarkSourceMessageSent(client, message);
                }
                return ok;
            }

            void MarkSourceMessageSent(ClientSession@ client, const Json::Value &in message) {
                if (client is null) return;

                string sourceId = MessageSourceId(message);
                if (sourceId.Length == 0 || sourceId == "service") return;

                client.MarkSourceSeqSent(sourceId, MessageSeq(message));
            }

            string MessageSourceId(const Json::Value &in message) {
                return string(message.Get("source", Json::Value("")));
            }

            uint64 MessageSeq(const Json::Value &in message) {
                uint64 seq = uint64(message.Get("seq", Json::Value(0)));
                return seq;
            }

            void CloseClientAt(uint index) {
                if (index >= g_clients.Length) return;
                if (g_clients[index] !is null) g_clients[index].Close();
                g_clients.RemoveAt(index);
                g_totalDisconnected++;
            }

            void CloseClients() {
                uint64 closed = 0;
                for (uint i = 0; i < g_clients.Length; i++) {
                    if (g_clients[i] !is null) {
                        g_clients[i].Close();
                        closed++;
                    }
                }
                g_clients.RemoveRange(0, g_clients.Length);
                g_totalDisconnected += closed;
            }

            void SendErrorAndClose(Net::Socket@ socket, const string &in code, const string &in message) {
                if (socket is null) return;
                try {
                    socket.WriteLine(Json::Write(DataSender::Shared::Messages::Error(code, message, Time::Now), false));
                } catch {
                }
                try {
                    socket.Close();
                } catch {
                }
            }

            void RecordError(const string &in message, int line, const string &in fn) {
                g_lastError = DataSender::Toolkit::Truncate(message, 512);
                log(
                    g_lastError,
                    LogLevel::Warning,
                    372,
                    "DataSender::Server::Tcp::RecordError"
                );
            }
        }
    }
}
