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

                void SetSubscriptions(const array<string> &in sourceIds) {
                    subscribedAll = false;
                    subscriptions.RemoveRange(0, subscriptions.Length);

                    for (uint i = 0; i < sourceIds.Length; i++) {
                        AddSubscription(sourceIds[i]);
                    }
                }

                void AddSubscription(const string &in sourceId) {
                    if (sourceId == "*" || sourceId == "all") {
                        SubscribeAll();
                        return;
                    }
                    if (DataSender::Sender::SourceRegistry::GetById(sourceId) is null) return;
                    if (subscriptions.Find(sourceId) < 0) subscriptions.InsertLast(sourceId);
                }

                void RemoveSubscription(const string &in sourceId) {
                    if (sourceId == "*" || sourceId == "all") {
                        subscribedAll = false;
                        subscriptions.RemoveRange(0, subscriptions.Length);
                        return;
                    }

                    int index = subscriptions.Find(sourceId);
                    if (index >= 0) subscriptions.RemoveAt(uint(index));
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

                void HandleCommand(const string &in line) {
                    Json::Value@ parsed = Json::Parse(line);
                    if (parsed is null) {
                        SendJson(DataSender::Shared::Messages::Error("invalid_json", "Command must be a JSON object line", Time::Now));
                        return;
                    }

                    string command = string(parsed.Get("type", Json::Value("")));
                    if (command == "subscribe") {
                        array<string> sourceIds = ReadSourceIds(parsed);
                        SetSubscriptions(sourceIds);
                        SendJson(DataSender::Shared::Messages::Ack("subscribe", "subscriptions updated", SubscriptionJson(), Time::Now));
                        return;
                    }

                    if (command == "subscribe_all") {
                        SubscribeAll();
                        SendJson(DataSender::Shared::Messages::Ack("subscribe_all", "subscribed to all sources", SubscriptionJson(), Time::Now));
                        return;
                    }

                    if (command == "unsubscribe") {
                        array<string> sourceIds = ReadSourceIds(parsed);
                        for (uint i = 0; i < sourceIds.Length; i++) {
                            RemoveSubscription(sourceIds[i]);
                        }
                        SendJson(DataSender::Shared::Messages::Ack("unsubscribe", "subscriptions updated", SubscriptionJson(), Time::Now));
                        return;
                    }

                    if (command == "status") {
                        SendJson(DataSender::Sender::Service::StatusMessage());
                        return;
                    }

                    if (command == "sources") {
                        Json::Value data = Json::Object();
                        data["sources"] = DataSender::Sender::SourceRegistry::StatusJson();
                        SendJson(DataSender::Shared::Messages::Ack("sources", "source registry", data, Time::Now));
                        return;
                    }

                    SendJson(DataSender::Shared::Messages::Error("unknown_command", "Unknown command type: " + command, Time::Now));
                }

                void Close() {
                    if (socket !is null) socket.Close();
                    @socket = null;
                }
            }

            array<string> ReadSourceIds(Json::Value@ command) {
                array<string> sourceIds;
                if (command is null) return sourceIds;

                Json::Value@ sources = command.Get("sources");
                if (sources is null) return sourceIds;

                for (uint i = 0; i < sources.Length; i++) {
                    string sourceId = string(sources[i]).Trim();
                    if (sourceId.Length == 0) continue;
                    sourceIds.InsertLast(sourceId);
                }
                return sourceIds;
            }
        }
    }
}
