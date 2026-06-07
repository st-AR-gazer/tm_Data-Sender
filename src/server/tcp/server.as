namespace DataSender {
    namespace Server {
        namespace Tcp {
            Net::Socket@ g_listener;
            array<ClientSession@> g_clients;
            bool g_running = false;
            string g_boundHost = "";
            uint16 g_boundPort = 0;
            string g_lastError = "";
            uint g_lastBroadcastAt = 0;
            uint g_nextStartAttemptAt = 0;
            uint g_totalAccepted = 0;
            uint g_totalMessagesSent = 0;

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

            uint TotalAccepted() {
                return g_totalAccepted;
            }

            uint TotalMessagesSent() {
                return g_totalMessagesSent;
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

                if (!g_listener.Listen(host, port)) {
                    g_lastError = "Could not listen on " + host + ":" + tostring(port);
                    g_nextStartAttemptAt = Time::Now + 3000;
                    @g_listener = null;
                    log(
                        g_lastError,
                        LogLevel::Warning,
                        67,
                        "Tcp::Start"
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
                    80,
                    "Tcp::Start"
                );
                return true;
            }

            void Stop() {
                CloseClients();
                if (g_listener !is null) {
                    g_listener.Close();
                    @g_listener = null;
                }
                if (g_running) {
                    log(
                        "TCP server stopped",
                        LogLevel::Info,
                        94,
                        "Tcp::Stop"
                    );
                }
                g_running = false;
                g_boundHost = "";
                g_boundPort = 0;
            }

            void Update(float dt) {
                EnsureRunning();
                if (!g_running) return;

                bool telemetryRunningAtStart = DataSender::Sender::Service::IsRunning();
                AcceptClients();
                UpdateClients();
                if (!telemetryRunningAtStart || !DataSender::Sender::Service::IsRunning()) return;

                uint now = Time::Now;
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
                root["totalAccepted"] = int(g_totalAccepted);
                root["messagesSent"] = int(g_totalMessagesSent);
                root["lastError"] = g_lastError;
                return root;
            }

            void AcceptClients() {
                if (g_listener is null) return;

                for (uint i = 0; i < 8; i++) {
                    Net::Socket@ socket = g_listener.Accept();
                    if (socket is null) break;

                    if (g_clients.Length >= MaxClients()) {
                        socket.WriteLine(Json::Write(DataSender::Shared::Messages::Error("max_clients", "DataSender TCP server is full", Time::Now), false));
                        socket.Close();
                        continue;
                    }

                    ClientSession@ client = ClientSession(socket, Time::Now);
                    g_clients.InsertLast(client);
                    g_totalAccepted++;
                    SendToClient(client, DataSender::Sender::Service::StatusMessage());
                    if (DataSender::Sender::Service::IsRunning()) SendLatestMessages(client);
                    log(
                        "TCP client connected",
                        LogLevel::Info,
                        152,
                        "Tcp::AcceptClients"
                    );
                }
            }

            void UpdateClients() {
                for (int i = int(g_clients.Length) - 1; i >= 0; i--) {
                    ClientSession@ client = g_clients[uint(i)];
                    if (client is null || !client.IsAlive()) {
                        CloseClientAt(uint(i));
                        continue;
                    }
                    client.DrainIncoming();
                }
            }

            void BroadcastTelemetry() {
                Broadcast(DataSender::Sender::Service::StatusMessage());
                Json::Value messages = DataSender::Sender::Service::LatestSourceMessages();

                for (uint i = 0; i < messages.Length; i++) {
                    BroadcastSourceMessage(messages[i]);
                }
            }

            void Broadcast(const Json::Value &in message) {
                for (int i = int(g_clients.Length) - 1; i >= 0; i--) {
                    ClientSession@ client = g_clients[uint(i)];
                    if (!SendToClient(client, message)) {
                        CloseClientAt(uint(i));
                    }
                }
            }

            void SendLatestMessages(ClientSession@ client) {
                Json::Value messages = DataSender::Sender::Service::LatestSourceMessages();
                for (uint i = 0; i < messages.Length; i++) {
                    if (!ShouldSendToClient(client, messages[i])) continue;
                    if (!SendToClient(client, messages[i])) return;
                }
            }

            void BroadcastSourceMessage(const Json::Value &in message) {
                for (int i = int(g_clients.Length) - 1; i >= 0; i--) {
                    ClientSession@ client = g_clients[uint(i)];
                    if (!ShouldSendToClient(client, message)) continue;

                    if (!SendToClient(client, message)) {
                        CloseClientAt(uint(i));
                    }
                }
            }

            bool ShouldSendToClient(ClientSession@ client, const Json::Value &in message) {
                if (client is null) return false;
                string sourceId = MessageSourceId(message);
                if (sourceId.Length == 0 || sourceId == "service") return true;
                if (!client.IsSubscribedTo(sourceId)) return false;

                uint seq = MessageSeq(message);
                if (client.HasSentSourceSeq(sourceId, seq)) return false;
                return true;
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

            uint MessageSeq(const Json::Value &in message) {
                int seq = int(message.Get("seq", Json::Value(0)));
                if (seq <= 0) return 0;
                return uint(seq);
            }

            void CloseClientAt(uint index) {
                if (index >= g_clients.Length) return;
                if (g_clients[index] !is null) g_clients[index].Close();
                g_clients.RemoveAt(index);
            }

            void CloseClients() {
                for (uint i = 0; i < g_clients.Length; i++) {
                    if (g_clients[i] !is null) g_clients[i].Close();
                }
                g_clients.RemoveRange(0, g_clients.Length);
            }
        }
    }
}
