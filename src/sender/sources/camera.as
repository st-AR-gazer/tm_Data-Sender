namespace DataSender {
    namespace Sources {
        namespace Camera {
            void Update(float dt) {
            }

            Json::Value GetJson() {
                Json::Value root = Json::Object();
                root["available"] = false;
                root["reason"] = "not implemented";
                return root;
            }
        }
    }
}
