namespace DataSender {
    namespace Shared {
        namespace Messages {
            const int PROTOCOL_VERSION = 1;

            Json::Value Snapshot(
                const string &in sourceId,
                const string &in sourceLabel,
                const Json::Value &in data,
                uint64 t,
                uint64 seq
            ) {
                Json::Value root = Json::Object();
                root["type"] = "snapshot";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = DataSender::Toolkit::JsonTime(t);
                root["source"] = sourceId;
                root["sourceLabel"] = sourceLabel;
                root["seq"] = DataSender::Toolkit::JsonCounter(seq);
                root["data"] = data;
                return root;
            }

            Json::Value ServiceStatus(const Json::Value &in status, uint64 t) {
                Json::Value root = Json::Object();
                root["type"] = "service_status";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = DataSender::Toolkit::JsonTime(t);
                root["source"] = "service";
                root["data"] = status;
                return root;
            }

            Json::Value Error(const string &in code, const string &in message, uint64 t) {
                Json::Value root = Json::Object();
                root["type"] = "error";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = DataSender::Toolkit::JsonTime(t);
                root["code"] = code;
                root["message"] = message;
                return root;
            }

            Json::Value Ack(const string &in command, const string &in message, const Json::Value &in data, uint64 t) {
                Json::Value root = Json::Object();
                root["type"] = "ack";
                root["version"] = PROTOCOL_VERSION;
                root["t"] = DataSender::Toolkit::JsonTime(t);
                root["command"] = command;
                root["message"] = message;
                root["data"] = data;
                return root;
            }
        }
    }
}
