namespace DataSender {
    namespace Sources {
        namespace CameraSource {
            Json::Value GetJson() {
                Json::Value root = Json::Object();

#if DEPENDENCY_CAMERA
                CHmsCamera@ camera = Camera::GetCurrent();
                if (camera is null) {
                    root["available"] = false;
                    root["reason"] = "no_current_camera";
                    return root;
                }

                root["available"] = true;
                root["position"] = Vec3Json(Camera::GetCurrentPosition());
                root["fov"] = camera.Fov;
                root["nearZ"] = camera.NearZ;
                root["farZ"] = camera.FarZ;
#if TMNEXT
                root["aspect"] = camera.Width_Height;
#else
                root["aspect"] = camera.RatioXY;
#endif

                Json::Value drawRect = Json::Object();
                drawRect["min"] = Vec2Json(camera.DrawRectMin);
                drawRect["max"] = Vec2Json(camera.DrawRectMax);
                root["drawRect"] = drawRect;

#if DEPENDENCY_VEHICLESTATE
                CSceneVehicleVisState@ vis = VehicleState::ViewingPlayerState();
                if (vis !is null) {
                    vec3 screenPos = Camera::ToScreen(vis.Position);
                    Json::Value vehicle = Json::Object();
                    vehicle["worldPosition"] = Vec3Json(vis.Position);
                    vehicle["screenPosition"] = Vec3Json(screenPos);
                    vehicle["behindCamera"] = Camera::IsBehind(vis.Position);
                    root["viewingVehicle"] = vehicle;
                }
#endif
#else
                root["available"] = false;
                root["reason"] = "camera_dependency_unavailable";
#endif
                return root;
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
        }
    }
}
