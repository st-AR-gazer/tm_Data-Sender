namespace DataSender {
    namespace Shared {
        namespace Messages {
            const int PROTOCOL_VERSION = 1;

            Json::Value Snapshot(
                const string &in sourceId,
                const string &in sourceLabel,
                const Json::Value &in data,
                uint t,
                uint seq
            ) {
                Json::Value root = Json::Object();
                root["type"] = "snapshot";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = int(t);
                root["source"] = sourceId;
                root["sourceLabel"] = sourceLabel;
                root["seq"] = int(seq);
                root["data"] = data;
                return root;
            }

            Json::Value ServiceStatus(const Json::Value &in status, uint t) {
                Json::Value root = Json::Object();
                root["type"] = "service_status";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = int(t);
                root["source"] = "service";
                root["data"] = status;
                return root;
            }

            Json::Value Error(const string &in code, const string &in message, uint t) {
                Json::Value root = Json::Object();
                root["type"] = "error";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = int(t);
                root["code"] = code;
                root["message"] = message;
                return root;
            }
        }
    }
}
