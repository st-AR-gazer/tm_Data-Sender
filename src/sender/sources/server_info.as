namespace DataSender {
    namespace Sources {
        namespace ServerInfo {
            Json::Value GetJson() {
                Json::Value root = Json::Object();
                root["available"] = false;
                root["reason"] = "not implemented";
                return root;
            }
        }
    }
}
