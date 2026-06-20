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
                    vehicle["worldPosition"] = DataSender::Sources::Helpers::Vec3Json(vis.Position);
                    vehicle["screenPosition"] = DataSender::Sources::Helpers::Vec3Json(screenPos);
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
                root["position"] = DataSender::Sources::Helpers::Vec3Json(cameraPosition);
                root["location"] = DataSender::Sources::Helpers::Iso4Json(camera.Location);
                root["nextLocation"] = DataSender::Sources::Helpers::Iso4Json(camera.NextLocation);
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
                root["clearColor"] = DataSender::Sources::Helpers::Vec3Json(camera.ClearColor);
                root["m_UseZBuffer"] = camera.m_UseZBuffer;
                root["scissorRect"] = camera.ScissorRect;
                root["fovRect"] = camera.FovRect;
                root["clearZBuffer"] = camera.ClearZBuffer;
                root["drawRect"] = DataSender::Sources::Helpers::RectJson(camera.DrawRectMin, camera.DrawRectMax);
                root["scissor"] = DataSender::Sources::Helpers::RectJson(camera.ScissorMin, camera.ScissorMax);
                root["fovRectBounds"] = DataSender::Sources::Helpers::RectJson(camera.FovRectMin, camera.FovRectMax);
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
                root["cameraMatrix"] = DataSender::Sources::Helpers::Mat4Json(cameraMatrix);
                root["viewMatrix"] = DataSender::Sources::Helpers::Mat4Json(viewMatrix);
                root["projectionMatrix"] = DataSender::Sources::Helpers::Mat4Json(projectionOnly);
                root["viewProjectionMatrix"] = DataSender::Sources::Helpers::Mat4Json(cameraPluginProjection);
                root["cameraPluginProjectionMatrix"] = DataSender::Sources::Helpers::Mat4Json(cameraPluginProjection);
                root["nextCameraMatrix"] = DataSender::Sources::Helpers::Mat4Json(mat4(camera.NextLocation));
                vec2 displaySize = Display::GetSize();
                vec2 displayPos = DisplayPos(camera, displaySize);
                vec2 projectedSize = DisplayProjectedSize(camera, displaySize);
                root["displaySize"] = DataSender::Sources::Helpers::Vec2Json(displaySize);
                root["displayPos"] = DataSender::Sources::Helpers::Vec2Json(displayPos);
                root["displayProjectedSize"] = DataSender::Sources::Helpers::Vec2Json(projectedSize);
                root["drawRect"] = DataSender::Sources::Helpers::RectJson(camera.DrawRectMin, camera.DrawRectMax);
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
        }
    }
}
