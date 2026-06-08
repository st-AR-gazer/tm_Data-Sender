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
                vec3 cameraPosition = Camera::GetCurrentPosition();
#if TMNEXT
                float aspect = camera.Width_Height;
#else
                float aspect = camera.RatioXY;
#endif
                root["camera"] = CameraJson(camera, cameraPosition, aspect);
                root["projection"] = ProjectionJson(camera, aspect);

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

            Json::Value CameraJson(CHmsCamera@ camera, const vec3 &in cameraPosition, float aspect) {
                Json::Value root = Json::Object();
                if (camera is null) return root;

                root["isActive"] = camera.IsActive;
                root["position"] = Vec3Json(cameraPosition);
                root["location"] = Iso4Json(camera.Location);
                root["nextLocation"] = Iso4Json(camera.NextLocation);
                root["m_IsPickEnable"] = camera.m_IsPickEnable;
                root["m_UseViewDependantRendering"] = camera.m_UseViewDependantRendering;
                root["m_ViewportRatio"] = tostring(camera.m_ViewportRatio);
                root["m_ViewportRatioValue"] = int(camera.m_ViewportRatio);
#if TMNEXT
                root["m_IsOverlay3d"] = camera.m_IsOverlay3d;
#else
                root["isOverlay3d"] = camera.IsOverlay3d;
#endif
                root["clearColorEnable"] = camera.ClearColorEnable;
                root["clearColor"] = Vec3Json(camera.ClearColor);
                root["m_UseZBuffer"] = camera.m_UseZBuffer;
                root["scissorRect"] = camera.ScissorRect;
                root["fovRect"] = camera.FovRect;
                root["clearZBuffer"] = camera.ClearZBuffer;
                root["drawRect"] = RectJson(camera.DrawRectMin, camera.DrawRectMax);
                root["scissor"] = RectJson(camera.ScissorMin, camera.ScissorMax);
                root["fovRectBounds"] = RectJson(camera.FovRectMin, camera.FovRectMax);
                root["nearZ"] = camera.NearZ;
                root["farZ"] = camera.FarZ;
                root["fov"] = camera.Fov;
                root["clampFovX"] = camera.ClampFovX;
                root["clampFovY"] = camera.ClampFovY;
                root["clampFovAuto"] = camera.ClampFovAuto;
                root["clampFovRatioXy"] = camera.ClampFovRatioXy;
                root["widthHeight"] = aspect;
                root["m_PickerAvailable"] = (camera.m_Picker !is null);
                root["m_GroupIndex"] = int(camera.m_GroupIndex);
                root["m_IsInternal"] = int(camera.m_IsInternal);
                root["waterTop"] = camera.WaterTop;
                root["waterIndex"] = int(camera.WaterIndex);
                root["isJustAboveWater"] = int(camera.IsJustAboveWater);
                root["isInsideWater"] = int(camera.IsInsideWater);
                return root;
            }

            Json::Value ProjectionJson(CHmsCamera@ camera, float aspect) {
                Json::Value root = Json::Object();
                if (camera is null) return root;

                mat4 projectionOnly = mat4::Perspective(camera.Fov, aspect, camera.NearZ, camera.FarZ);
                mat4 cameraMatrix = mat4(camera.Location);
                mat4 viewMatrix = mat4::Inverse(cameraMatrix);
                mat4 cameraPluginProjection = Camera::GetProjectionMatrix();

                root["cameraMatrix"] = Mat4Json(cameraMatrix);
                root["viewMatrix"] = Mat4Json(viewMatrix);
                root["projectionMatrix"] = Mat4Json(projectionOnly);
                root["viewProjectionMatrix"] = Mat4Json(cameraPluginProjection);
                root["cameraPluginProjectionMatrix"] = Mat4Json(cameraPluginProjection);
                root["nextCameraMatrix"] = Mat4Json(mat4(camera.NextLocation));

                vec2 displaySize = Display::GetSize();
                vec2 displayPos = DisplayPos(camera, displaySize);
                vec2 projectedSize = DisplayProjectedSize(camera, displaySize);
                root["displaySize"] = Vec2Json(displaySize);
                root["displayPos"] = Vec2Json(displayPos);
                root["displayProjectedSize"] = Vec2Json(projectedSize);
                root["drawRect"] = RectJson(camera.DrawRectMin, camera.DrawRectMax);
                root["toScreenBehindWhenWGreaterThanZero"] = true;
                return root;
            }

            vec2 DisplayPos(CHmsCamera@ camera, const vec2 &in displaySize) {
                vec2 topLeft = 1.0f - (camera.DrawRectMax + 1.0f) / 2.0f;
                return topLeft * displaySize;
            }

            vec2 DisplayProjectedSize(CHmsCamera@ camera, const vec2 &in displaySize) {
                vec2 topLeft = 1.0f - (camera.DrawRectMax + 1.0f) / 2.0f;
                vec2 bottomRight = 1.0f - (camera.DrawRectMin + 1.0f) / 2.0f;
                return displaySize * (bottomRight - topLeft);
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
        }
    }
}
