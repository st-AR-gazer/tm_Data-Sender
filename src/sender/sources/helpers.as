namespace DataSender {
    namespace Sources {
        namespace Helpers {
            int64 UIntJson(uint value) {
                return DataSender::Toolkit::JsonCounter(uint64(value));
            }

            Json::Value StringArrayJson(const array<string> @values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(values[i]);
                }
                return arr;
            }

            Json::Value IntArrayJson(const array<int> @values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(values[i]);
                }
                return arr;
            }

            Json::Value IntArrayValueJson(const array<int> &in values) {
                Json::Value arr = Json::Array();
                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(values[i]);
                }
                return arr;
            }

            Json::Value UIntArrayJson(const array<uint> @values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(UIntJson(values[i]));
                }
                return arr;
            }

            Json::Value RectJson(const vec2 &in min, const vec2 &in max) {
                Json::Value root = Json::Object();
                root["min"] = Vec2Json(min);
                root["max"] = Vec2Json(max);
                return root;
            }

            Json::Value Iso4Json(const iso4 &in value) {
                Json::Value root = Json::Object();
                root["translation"] = Vec3Json(vec3(value.tx, value.ty, value.tz));
                root["matrix"] = Mat4Json(mat4(value));
                return root;
            }

            Json::Value Mat4Json(const mat4 &in value) {
                Json::Value columns = Json::Array();
                columns.Add(Vec4Json(value * vec4(1.0f, 0.0f, 0.0f, 0.0f)));
                columns.Add(Vec4Json(value * vec4(0.0f, 1.0f, 0.0f, 0.0f)));
                columns.Add(Vec4Json(value * vec4(0.0f, 0.0f, 1.0f, 0.0f)));
                columns.Add(Vec4Json(value * vec4(0.0f, 0.0f, 0.0f, 1.0f)));
                return columns;
            }

            Json::Value Vec2Json(const vec2 &in value) {
                Json::Value arr = Json::Array();
                arr.Add(value.x);
                arr.Add(value.y);
                return arr;
            }

            Json::Value Vec3Json(const vec3 &in value) {
                Json::Value arr = Json::Array();
                arr.Add(value.x);
                arr.Add(value.y);
                arr.Add(value.z);
                return arr;
            }

            Json::Value Vec4Json(const vec4 &in value) {
                Json::Value arr = Json::Array();
                arr.Add(value.x);
                arr.Add(value.y);
                arr.Add(value.z);
                arr.Add(value.w);
                return arr;
            }

#if DEPENDENCY_MLFEEDRACEDATA
            Json::Value MwIdJson(const MwId &in id) {
                Json::Value root = Json::Object();
                root["value"] = UIntJson(id.Value);
                root["name"] = id.GetName();
                return root;
            }

            Json::Value PlayerIdentityJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = Json::Object();
                if (player is null) return root;

                root["name"] = player.Name;
                root["login"] = player.Login;
                root["wsid"] = player.WebServicesUserId;
                root["loginMwId"] = MwIdJson(player.LoginMwId);
                root["nameMwId"] = MwIdJson(player.NameMwId);
                return root;
            }

            Json::Value RaceProgressionJson(const int2 &in value) {
                Json::Value root = Json::Object();
                root["x"] = value.x;
                root["y"] = value.y;
                root["points"] = value.x;
                root["time"] = value.y;
                return root;
            }
#endif
        }
    }
}
