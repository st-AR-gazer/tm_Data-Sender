namespace DataSender {
    namespace Server {
        namespace Tcp {
            class ClientSession {
                Net::Socket@ socket;
                string remoteIp;
                uint connectedAt;
                uint messagesSent;
                bool subscribedAll;
                array<string> subscriptions;
                array<string> lastSentSourceIds;
                array<uint> lastSentSourceSeqs;

                ClientSession(Net::Socket@ socket, uint connectedAt) {
                    @this.socket = socket;
                    this.remoteIp = "";
                    if (socket !is null) this.remoteIp = socket.GetRemoteIP();
                    this.connectedAt = connectedAt;
                    this.messagesSent = 0;
                    this.subscribedAll = true;
                }

                bool IsAlive() {
                    return socket !is null && !socket.IsHungUp();
                }

                void DrainIncoming() {
                    if (socket is null) return;

                    string line;
                    for (uint i = 0; i < 16; i++) {
                        if (!socket.ReadLine(line)) break;
                        line = line.Trim();
                        if (line.Length == 0) continue;
                        HandleCommand(line);
                    }
                }

                bool SendJson(const Json::Value &in message) {
                    if (!IsAlive()) return false;
                    bool ok = socket.WriteLine(Json::Write(message, false));
                    if (ok) messagesSent++;
                    return ok;
                }

                bool IsSubscribedTo(const string &in sourceId) {
                    if (subscribedAll) return true;
                    return subscriptions.Find(sourceId) >= 0;
                }

                uint LastSentSourceSeq(const string &in sourceId) {
                    int index = lastSentSourceIds.Find(sourceId);
                    if (index < 0) return 0;
                    return lastSentSourceSeqs[uint(index)];
                }

                bool HasSentSourceSeq(const string &in sourceId, uint seq) {
                    if (sourceId.Length == 0 || seq == 0) return false;
                    return LastSentSourceSeq(sourceId) >= seq;
                }

                void MarkSourceSeqSent(const string &in sourceId, uint seq) {
                    if (sourceId.Length == 0 || seq == 0) return;

                    int index = lastSentSourceIds.Find(sourceId);
                    if (index < 0) {
                        lastSentSourceIds.InsertLast(sourceId);
                        lastSentSourceSeqs.InsertLast(seq);
                        return;
                    }

                    lastSentSourceSeqs[uint(index)] = seq;
                }

                string RemoteIP() {
                    if (remoteIp.Length > 0) return remoteIp;
                    if (socket is null) return "";
                    remoteIp = socket.GetRemoteIP();
                    return remoteIp;
                }

                string SubscriptionText() {
                    if (subscribedAll) return "all";
                    if (subscriptions.Length == 0) return "none";

                    string text = "";
                    for (uint i = 0; i < subscriptions.Length; i++) {
                        if (text.Length > 0) text += ", ";
                        text += subscriptions[i];
                    }
                    return text;
                }

                void SubscribeAll() {
                    subscribedAll = true;
                    subscriptions.RemoveRange(0, subscriptions.Length);
                }

                Json::Value SetSubscriptions(const array<string> &in sourceIds) {
                    Json::Value accepted = Json::Array();
                    Json::Value rejected = Json::Array();
                    subscribedAll = false;
                    subscriptions.RemoveRange(0, subscriptions.Length);

                    for (uint i = 0; i < sourceIds.Length; i++) {
                        if (AddSubscription(sourceIds[i])) {
                            accepted.Add(NormalizedSubscriptionSourceId(sourceIds[i]));
                        } else {
                            rejected.Add(sourceIds[i]);
                        }
                    }

                    return SubscriptionResultJson(accepted, rejected);
                }

                bool AddSubscription(const string &in sourceId) {
                    if (IsAllSourceId(sourceId)) {
                        SubscribeAll();
                        return true;
                    }
                    if (DataSender::Sender::SourceRegistry::GetById(sourceId) is null) return false;
                    if (subscribedAll) return true;
                    if (subscriptions.Find(sourceId) < 0) subscriptions.InsertLast(sourceId);
                    return true;
                }

                Json::Value RemoveSubscriptions(const array<string> &in sourceIds) {
                    Json::Value accepted = Json::Array();
                    Json::Value rejected = Json::Array();

                    for (uint i = 0; i < sourceIds.Length; i++) {
                        if (RemoveSubscription(sourceIds[i])) {
                            accepted.Add(NormalizedSubscriptionSourceId(sourceIds[i]));
                        } else {
                            rejected.Add(sourceIds[i]);
                        }
                    }

                    return SubscriptionResultJson(accepted, rejected);
                }

                bool RemoveSubscription(const string &in sourceId) {
                    if (IsAllSourceId(sourceId)) {
                        subscribedAll = false;
                        subscriptions.RemoveRange(0, subscriptions.Length);
                        return true;
                    }
                    if (DataSender::Sender::SourceRegistry::GetById(sourceId) is null) return false;

                    int index = subscriptions.Find(sourceId);
                    if (index >= 0) subscriptions.RemoveAt(uint(index));
                    return true;
                }

                Json::Value SubscriptionJson() {
                    Json::Value root = Json::Object();
                    root["all"] = subscribedAll;
                    Json::Value sources = Json::Array();
                    for (uint i = 0; i < subscriptions.Length; i++) {
                        sources.Add(subscriptions[i]);
                    }
                    root["sources"] = sources;
                    return root;
                }

                Json::Value SubscriptionResultJson(const Json::Value &in accepted, const Json::Value &in rejected) {
                    Json::Value root = Json::Object();
                    root["accepted"] = accepted;
                    root["rejected"] = rejected;
                    root["subscription"] = SubscriptionJson();
                    return root;
                }

                bool IsAllSourceId(const string &in sourceId) {
                    return sourceId == "*" || sourceId == "all";
                }

                string NormalizedSubscriptionSourceId(const string &in sourceId) {
                    return IsAllSourceId(sourceId) ? "all" : sourceId;
                }

                void HandleCommand(const string &in line) {
                    Json::Value@ parsed = Json::Parse(line);
                    if (parsed is null) {
                        SendJson(DataSender::Shared::Messages::Error("invalid_json", "Command must be a JSON object line", Time::Now));
                        return;
                    }

                    string command = string(parsed.Get("type", Json::Value("")));
                    if (command == "service.start" || command == "start") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        DataSender::Sender::Service::Start();
                        SendServiceControlAck(command, "service started");
                        return;
                    }

                    if (command == "service.stop" || command == "stop") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        DataSender::Sender::Service::Stop();
                        SendServiceControlAck(command, "service stopped");
                        return;
                    }

                    if (command == "service.restart" || command == "restart") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        DataSender::Sender::Service::Stop();
                        DataSender::Sender::Service::Start();
                        SendServiceControlAck(command, "service restarted");
                        return;
                    }

                    if (command == "source.enable") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        HandleSourceSetEnabled(parsed, command, true);
                        return;
                    }

                    if (command == "source.disable") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        HandleSourceSetEnabled(parsed, command, false);
                        return;
                    }

                    if (command == "source.set_enabled") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        Json::Value@ enabledValue = parsed.Get("enabled");
                        if (enabledValue is null) {
                            SendJson(DataSender::Shared::Messages::Error("missing_enabled", "Command requires an enabled boolean", Time::Now));
                            return;
                        }

                        bool enabled = bool(parsed.Get("enabled", Json::Value(false)));
                        HandleSourceSetEnabled(parsed, command, enabled);
                        return;
                    }

                    if (command == "source.set_interval") {
                        if (!EnsureControlCommandsAllowed(command)) return;
                        HandleSourceSetInterval(parsed, command);
                        return;
                    }

                    if (command == "subscribe") {
                        array<string> sourceIds = ReadSourceIds(parsed);
                        SendJson(DataSender::Shared::Messages::Ack("subscribe", "subscriptions updated", SetSubscriptions(sourceIds), Time::Now));
                        return;
                    }

                    if (command == "subscribe_all") {
                        SubscribeAll();
                        Json::Value accepted = Json::Array();
                        accepted.Add("all");
                        Json::Value rejected = Json::Array();
                        SendJson(DataSender::Shared::Messages::Ack("subscribe_all", "subscribed to all sources", SubscriptionResultJson(accepted, rejected), Time::Now));
                        return;
                    }

                    if (command == "unsubscribe") {
                        array<string> sourceIds = ReadSourceIds(parsed);
                        SendJson(DataSender::Shared::Messages::Ack("unsubscribe", "subscriptions updated", RemoveSubscriptions(sourceIds), Time::Now));
                        return;
                    }

                    if (command == "status" || command == "service.status") {
                        SendJson(DataSender::Sender::Service::StatusMessage());
                        return;
                    }

                    if (command == "sources" || command == "source.list" || command == "sources.list") {
                        Json::Value data = Json::Object();
                        data["sources"] = DataSender::Sender::SourceRegistry::StatusJson();
                        SendJson(DataSender::Shared::Messages::Ack("sources", "source registry", data, Time::Now));
                        return;
                    }

                    SendJson(DataSender::Shared::Messages::Error("unknown_command", "Unknown command type: " + command, Time::Now));
                }

                bool EnsureControlCommandsAllowed(const string &in command) {
                    if (S_AllowControlCommands) return true;

                    SendJson(DataSender::Shared::Messages::Error("control_commands_disabled", "Control command disabled by TCP server settings: " + command, Time::Now));
                    return false;
                }

                void HandleSourceSetEnabled(Json::Value@ commandData, const string &in command, bool enabled) {
                    string sourceId = ReadSourceId(commandData);
                    if (sourceId.Length == 0) {
                        SendJson(DataSender::Shared::Messages::Error("missing_source", "Command requires a source id", Time::Now));
                        return;
                    }

                    if (!DataSender::Sender::SourceRegistry::SetEnabled(sourceId, enabled)) {
                        SendJson(DataSender::Shared::Messages::Error("unknown_source", "Unknown source id: " + sourceId, Time::Now));
                        return;
                    }

                    SendSourceControlAck(command, enabled ? "source enabled" : "source disabled", sourceId);
                }

                void HandleSourceSetInterval(Json::Value@ commandData, const string &in command) {
                    string sourceId = ReadSourceId(commandData);
                    if (sourceId.Length == 0) {
                        SendJson(DataSender::Shared::Messages::Error("missing_source", "Command requires a source id", Time::Now));
                        return;
                    }

                    Json::Value@ intervalValue = commandData.Get("intervalMs");
                    if (intervalValue is null) {
                        SendJson(DataSender::Shared::Messages::Error("missing_interval", "Command requires intervalMs", Time::Now));
                        return;
                    }

                    int intervalMs = int(commandData.Get("intervalMs", Json::Value(1)));
                    if (!DataSender::Sender::SourceRegistry::SetIntervalMs(sourceId, uint(Math::Clamp(intervalMs, 1, 1000)))) {
                        SendJson(DataSender::Shared::Messages::Error("unknown_source", "Unknown source id: " + sourceId, Time::Now));
                        return;
                    }

                    SendSourceControlAck(command, "source interval updated", sourceId);
                }

                void SendServiceControlAck(const string &in command, const string &in message) {
                    Json::Value data = Json::Object();
                    data["service"] = DataSender::Sender::Service::StatusJson();
                    SendJson(DataSender::Shared::Messages::Ack(command, message, data, Time::Now));
                }

                void SendSourceControlAck(
                    const string &in command,
                    const string &in message,
                    const string &in sourceId
                ) {
                    Json::Value data = Json::Object();
                    data["source"] = DataSender::Sender::SourceRegistry::SourceStatusJson(sourceId);
                    SendJson(DataSender::Shared::Messages::Ack(command, message, data, Time::Now));
                }

                void Close() {
                    if (socket !is null) socket.Close();
                    @socket = null;
                }
            }

            array<string> ReadSourceIds(Json::Value@ command) {
                array<string> sourceIds;
                if (command is null) return sourceIds;

                string sourceId = ReadSourceId(command);
                if (sourceId.Length > 0) sourceIds.InsertLast(sourceId);

                Json::Value@ sources = command.Get("sources");
                if (sources is null) return sourceIds;

                for (uint i = 0; i < sources.Length; i++) {
                    string sourceId = string(sources[i]).Trim();
                    if (sourceId.Length == 0) continue;
                    sourceIds.InsertLast(sourceId);
                }
                return sourceIds;
            }

            string ReadSourceId(Json::Value@ command) {
                if (command is null) return "";

                string sourceId = string(command.Get("source", Json::Value(""))).Trim();
                if (sourceId.Length == 0) {
                    sourceId = string(command.Get("id", Json::Value(""))).Trim();
                }
                return sourceId;
            }
        }
    }
}
