namespace DataSender {
    namespace Sources {
        namespace VehicleStateSource {
            class Snapshot {
                uint64 t;
                float spd;
                float sspd;
                float frontSpeed;
                vec3 pos;
                vec3 worldVel;
                vec3 left;
                vec3 up;
                vec3 dir;
                float steer;
                float throttle;
                float brake;
                bool inputIsBraking;
                bool finished;
                float accel;
                float jerk;
                float rpm;
                vec3 reactorAC;
                float groundDist;
                bool groundContact;
                bool reactorGround;
                int gear;

#if TMNEXT
                float inputVertical;
                vec3 worldCarUp;
                int reactorBoostLvl;
                string reactorBoostLvlName;
                int reactorBoostType;
                string reactorBoostTypeName;
                bool reactorInputsX;
                bool wheelsBurning;
                bool topContact;
                bool isTurbo;
                bool engineOn;
                uint raceStartTime;
                uint discontinuityCount;
                float bulletTimeNormed;
                float simulationTimeCoef;
                float airBrakeNormed;
                float spoilerOpenNormed;
                float wingsOpenNormed;
                float turboTime;
                float wetnessValue01;
                float waterImmersionCoef;
                float waterOverDistNormed;
                vec3 waterOverSurfacePos;
#endif

#if MP4 || TURBO
                uint activeEffects;
                bool turboActive;
                float turboPercent;
#endif
#if MP4
                float gearPercent;
#endif

                float reactorTimer;
                int lastTurbo;
                string lastTurboName;
                int cruiseSpeed;
                int vehicleType;
                string vehicleTypeName;
                float steerAngFL, steerAngFR, steerAngRL, steerAngRR;
                float wheelRotFL, wheelRotFR, wheelRotRL, wheelRotRR;
                float wheelRotSpeedFL, wheelRotSpeedFR, wheelRotSpeedRL, wheelRotSpeedRR;
                float damperFL, damperFR, damperRL, damperRR;
                float slipFL, slipFR, slipRL, slipRR;
                int matFL, matFR, matRL, matRR;
                float dirtFL, dirtFR, dirtRL, dirtRR;
                int fallFL, fallFR, fallRL, fallRR;
                string fallNameFL, fallNameFR, fallNameRL, fallNameRR;

#if TMNEXT
                float breakNormedFL, breakNormedFR, breakNormedRL, breakNormedRR;
                float icingFL, icingFR, icingRL, icingRR;
                float tireWearFL, tireWearFR, tireWearRL, tireWearRR;
#endif
#if MP4 || TURBO || FOREVER
                bool contactFL, contactFR, contactRL, contactRR;
#endif
#if MP4
                bool wetFL, wetFR, wetRL, wetRR;
#endif

                Json::Value ToJson() const {
                    Json::Value o = Json::Object();
                    o["available"] = true;
                    o["t"] = DataSender::Toolkit::JsonTime(t);
                    o["spd"] = spd;
                    o["sspd"] = sspd;
                    o["frontSpeed"] = frontSpeed;
                    o["pos"] = DataSender::Sources::Helpers::Vec3Json(pos);
                    o["worldVel"] = DataSender::Sources::Helpers::Vec3Json(worldVel);
                    o["left"] = DataSender::Sources::Helpers::Vec3Json(left);
                    o["up"] = DataSender::Sources::Helpers::Vec3Json(up);
                    o["dir"] = DataSender::Sources::Helpers::Vec3Json(dir);
                    o["steer"] = steer;
                    o["throttle"] = throttle;
                    o["brake"] = brake;
                    o["inputIsBraking"] = inputIsBraking;
                    o["finished"] = finished;
                    o["accel"] = accel;
                    o["jerk"] = jerk;
                    o["rpm"] = rpm;
                    o["reactorAC"] = DataSender::Sources::Helpers::Vec3Json(reactorAC);
                    o["groundDist"] = groundDist;
                    o["groundContact"] = groundContact;
                    o["reactorGnd"] = reactorGround;
                    o["gear"] = gear;
                    o["reactorT"] = reactorTimer;
                    o["lastTurbo"] = lastTurbo;
                    o["lastTurboName"] = lastTurboName;
                    o["cruiseSpd"] = cruiseSpeed;
                    o["vehType"] = vehicleType;
                    o["vehicleTypeName"] = vehicleTypeName;
                    o["FL"] = WheelJson(steerAngFL, wheelRotFL, wheelRotSpeedFL, damperFL, slipFL, matFL, dirtFL, fallFL, fallNameFL
#if TMNEXT
                    , breakNormedFL, icingFL, tireWearFL
#endif
#if MP4 || TURBO || FOREVER
                    , contactFL
#endif
#if MP4
                    , wetFL
#endif
                    );
                    o["FR"] = WheelJson(steerAngFR, wheelRotFR, wheelRotSpeedFR, damperFR, slipFR, matFR, dirtFR, fallFR, fallNameFR
#if TMNEXT
                    , breakNormedFR, icingFR, tireWearFR
#endif
#if MP4 || TURBO || FOREVER
                    , contactFR
#endif
#if MP4
                    , wetFR
#endif
                    );
                    o["RL"] = WheelJson(steerAngRL, wheelRotRL, wheelRotSpeedRL, damperRL, slipRL, matRL, dirtRL, fallRL, fallNameRL
#if TMNEXT
                    , breakNormedRL, icingRL, tireWearRL
#endif
#if MP4 || TURBO || FOREVER
                    , contactRL
#endif
#if MP4
                    , wetRL
#endif
                    );
                    o["RR"] = WheelJson(steerAngRR, wheelRotRR, wheelRotSpeedRR, damperRR, slipRR, matRR, dirtRR, fallRR, fallNameRR
#if TMNEXT
                    , breakNormedRR, icingRR, tireWearRR
#endif
#if MP4 || TURBO || FOREVER
                    , contactRR
#endif
#if MP4
                    , wetRR
#endif
                    );
                    o["vehicleState"] = VehicleStateJson();
                    return o;
                }

                Json::Value VehicleStateJson() const {
                    Json::Value root = Json::Object();
                    root["sampledAt"] = DataSender::Toolkit::JsonTime(t);
                    root["finished"] = finished;
                    Json::Value pose = Json::Object();
                    pose["position"] = DataSender::Sources::Helpers::Vec3Json(pos);
                    pose["left"] = DataSender::Sources::Helpers::Vec3Json(left);
                    pose["up"] = DataSender::Sources::Helpers::Vec3Json(up);
                    pose["dir"] = DataSender::Sources::Helpers::Vec3Json(dir);
#if TMNEXT
                    pose["worldCarUp"] = DataSender::Sources::Helpers::Vec3Json(worldCarUp);
#endif
                    root["pose"] = pose;
                    Json::Value velocity = Json::Object();
                    velocity["world"] = DataSender::Sources::Helpers::Vec3Json(worldVel);
                    velocity["speed"] = spd;
                    velocity["speedKph"] = spd * 3.6f;
                    velocity["frontSpeed"] = frontSpeed;
                    velocity["frontSpeedKph"] = frontSpeed * 3.6f;
                    velocity["sideSpeed"] = sspd;
                    velocity["sideSpeedKph"] = sspd * 3.6f;
                    velocity["acceleration"] = accel;
                    velocity["jerk"] = jerk;
                    root["velocity"] = velocity;
                    Json::Value inputs = Json::Object();
                    inputs["steer"] = steer;
                    inputs["gasPedal"] = throttle;
                    inputs["brakePedal"] = brake;
                    inputs["isBraking"] = inputIsBraking;
#if TMNEXT
                    inputs["vertical"] = inputVertical;
#endif
                    root["inputs"] = inputs;
                    Json::Value contact = Json::Object();
                    contact["isGroundContact"] = groundContact;
                    contact["groundDist"] = groundDist;
#if TMNEXT
                    contact["isTopContact"] = topContact;
                    contact["isWheelsBurning"] = wheelsBurning;
#endif
                    root["contact"] = contact;
                    Json::Value reactor = Json::Object();
                    reactor["airControl"] = DataSender::Sources::Helpers::Vec3Json(reactorAC);
                    reactor["isGroundMode"] = reactorGround;
                    reactor["finalTimer"] = reactorTimer;
#if TMNEXT
                    reactor["boostLvl"] = reactorBoostLvlName;
                    reactor["boostLvlValue"] = reactorBoostLvl;
                    reactor["boostType"] = reactorBoostTypeName;
                    reactor["boostTypeValue"] = reactorBoostType;
                    reactor["inputsX"] = reactorInputsX;
#endif
                    root["reactor"] = reactor;
                    Json::Value engine = Json::Object();
                    engine["rpm"] = rpm;
                    engine["curGear"] = gear;
                    engine["lastTurboLevel"] = lastTurboName;
                    engine["lastTurboLevelValue"] = lastTurbo;
                    engine["cruiseDisplaySpeed"] = cruiseSpeed;
                    engine["vehicleType"] = vehicleTypeName;
                    engine["vehicleTypeValue"] = vehicleType;
#if TMNEXT
                    engine["engineOn"] = engineOn;
                    engine["isTurbo"] = isTurbo;
                    engine["turboTime"] = turboTime;
                    engine["raceStartTime"] = DataSender::Toolkit::JsonCounter(uint64(raceStartTime));
#endif
#if MP4 || TURBO
                    engine["activeEffects"] = DataSender::Toolkit::JsonCounter(uint64(activeEffects));
                    engine["turboActive"] = turboActive;
                    engine["turboPercent"] = turboPercent;
#endif
#if MP4
                    engine["gearPercent"] = gearPercent;
#endif
                    root["engine"] = engine;

#if TMNEXT
                    Json::Value dynamics = Json::Object();
                    dynamics["bulletTimeNormed"] = bulletTimeNormed;
                    dynamics["simulationTimeCoef"] = simulationTimeCoef;
                    dynamics["airBrakeNormed"] = airBrakeNormed;
                    dynamics["spoilerOpenNormed"] = spoilerOpenNormed;
                    dynamics["wingsOpenNormed"] = wingsOpenNormed;
                    dynamics["discontinuityCount"] = DataSender::Toolkit::JsonCounter(uint64(discontinuityCount));
                    root["dynamics"] = dynamics;
                    Json::Value water = Json::Object();
                    water["wetnessValue01"] = wetnessValue01;
                    water["immersionCoef"] = waterImmersionCoef;
                    water["overDistNormed"] = waterOverDistNormed;
                    water["overSurfacePos"] = DataSender::Sources::Helpers::Vec3Json(waterOverSurfacePos);
                    root["water"] = water;
#endif

                    Json::Value wheels = Json::Object();
                    wheels["frontLeft"] = oFL();
                    wheels["frontRight"] = oFR();
                    wheels["rearLeft"] = oRL();
                    wheels["rearRight"] = oRR();
                    root["wheels"] = wheels;
                    return root;
                }

                Json::Value oFL() const {
                    return WheelJson(steerAngFL, wheelRotFL, wheelRotSpeedFL, damperFL, slipFL, matFL, dirtFL, fallFL, fallNameFL
#if TMNEXT
                    , breakNormedFL, icingFL, tireWearFL
#endif
#if MP4 || TURBO || FOREVER
                    , contactFL
#endif
#if MP4
                    , wetFL
#endif
                    );
                }

                Json::Value oFR() const {
                    return WheelJson(steerAngFR, wheelRotFR, wheelRotSpeedFR, damperFR, slipFR, matFR, dirtFR, fallFR, fallNameFR
#if TMNEXT
                    , breakNormedFR, icingFR, tireWearFR
#endif
#if MP4 || TURBO || FOREVER
                    , contactFR
#endif
#if MP4
                    , wetFR
#endif
                    );
                }

                Json::Value oRL() const {
                    return WheelJson(steerAngRL, wheelRotRL, wheelRotSpeedRL, damperRL, slipRL, matRL, dirtRL, fallRL, fallNameRL
#if TMNEXT
                    , breakNormedRL, icingRL, tireWearRL
#endif
#if MP4 || TURBO || FOREVER
                    , contactRL
#endif
#if MP4
                    , wetRL
#endif
                    );
                }

                Json::Value oRR() const {
                    return WheelJson(steerAngRR, wheelRotRR, wheelRotSpeedRR, damperRR, slipRR, matRR, dirtRR, fallRR, fallNameRR
#if TMNEXT
                    , breakNormedRR, icingRR, tireWearRR
#endif
#if MP4 || TURBO || FOREVER
                    , contactRR
#endif
#if MP4
                    , wetRR
#endif
                    );
                }

                Json::Value WheelJson(float steerAng, float wheelRot, float wheelRotSpeed, float damper, float slip, int mat, float dirt, int fall, const string &in fallName
#if TMNEXT
                , float breakNormed, float icing, float tireWear
#endif
#if MP4 || TURBO || FOREVER
                , bool contact
#endif
#if MP4
                , bool wet
#endif
                ) const {
                    Json::Value root = Json::Object();
                    root["steerAng"] = steerAng;
                    root["steerAngle"] = steerAng;
                    root["rot"] = wheelRot;
                    root["wheelRot"] = wheelRot;
                    root["wheelRotSpeed"] = wheelRotSpeed;
                    root["damper"] = damper;
                    root["damperLen"] = damper;
                    root["slip"] = slip;
                    root["slipCoef"] = slip;
                    root["mat"] = mat;
                    root["groundContactMaterial"] = mat;
                    root["dirt"] = dirt;
                    root["fall"] = fall;
                    root["falling"] = fallName;
                    root["fallingValue"] = fall;
#if TMNEXT
                    root["breakNormedCoef"] = breakNormed;
                    root["icing01"] = icing;
                    root["tireWear01"] = tireWear;
#endif
#if MP4 || TURBO || FOREVER
                    root["groundContact"] = contact;
#endif
#if MP4
                    root["isWet"] = wet;
#endif
                    return root;
                }
            }

            Snapshot@ g_latest = null;
            float g_prevSpeed = 0.0f;
            float g_prevAccel = 0.0f;
            bool g_ready = false;
            string g_unavailableReason = "not_sampled_yet";

            Json::Value Unavailable(const string &in reason) {
                Json::Value root = Json::Object();
                root["available"] = false;
                root["reason"] = reason;
                return root;
            }

            void Update(float dt) {
#if DEPENDENCY_VEHICLESTATE
                if (dt <= 0) dt = 0.016f;

                CSceneVehicleVisState@ vis = VehicleState::ViewingPlayerState();
                if (vis is null) {
                    @g_latest = null;
                    g_ready = false;
                    g_unavailableReason = "no_viewing_player_state";
                    return;
                }

                Snapshot s;
                s.t = Time::Now;
                s.pos = vis.Position;
                s.worldVel = vis.WorldVel;
                s.left = vis.Left;
                s.up = vis.Up;
                s.dir = vis.Dir;
                s.frontSpeed = vis.FrontSpeed;
                // side speed sohuld only be accessable in dev mode
#if SIG_DEVELOPER
                s.sspd = VehicleState::GetSideSpeed(vis);
#else
                s.sspd = 404.0f;
#endif
                float speed = vis.WorldVel.Length();
                s.spd = speed;
                s.accel = (speed - g_prevSpeed) / dt;
                s.jerk = (s.accel - g_prevAccel) / dt;
                g_prevSpeed = speed;
                g_prevAccel = s.accel;
                s.steer = vis.InputSteer;
                s.throttle = vis.InputGasPedal;
                s.brake = vis.InputBrakePedal;
                s.inputIsBraking = vis.InputIsBraking;
                s.groundContact = vis.IsGroundContact;
                s.reactorGround = vis.IsReactorGroundMode;
                s.groundDist = vis.GroundDist;
                s.reactorAC = vis.ReactorAirControl;
                s.gear = int(vis.CurGear);
                s.rpm = VehicleState::GetRPM(vis);

#if TMNEXT
                s.inputVertical = vis.InputVertical;
                s.worldCarUp = vis.WorldCarUp;
                s.reactorBoostLvl = int(vis.ReactorBoostLvl);
                s.reactorBoostLvlName = tostring(vis.ReactorBoostLvl);
                s.reactorBoostType = int(vis.ReactorBoostType);
                s.reactorBoostTypeName = tostring(vis.ReactorBoostType);
                s.reactorInputsX = vis.ReactorInputsX;
                s.wheelsBurning = vis.IsWheelsBurning;
                s.topContact = vis.IsTopContact;
                s.isTurbo = vis.IsTurbo;
                s.engineOn = vis.EngineOn;
                s.raceStartTime = vis.RaceStartTime;
                s.discontinuityCount = uint(vis.DiscontinuityCount);
                s.bulletTimeNormed = vis.BulletTimeNormed;
                s.simulationTimeCoef = vis.SimulationTimeCoef;
                s.airBrakeNormed = vis.AirBrakeNormed;
                s.spoilerOpenNormed = vis.SpoilerOpenNormed;
                s.wingsOpenNormed = vis.WingsOpenNormed;
                s.turboTime = vis.TurboTime;
                s.wetnessValue01 = vis.WetnessValue01;
                s.waterImmersionCoef = vis.WaterImmersionCoef;
                s.waterOverDistNormed = vis.WaterOverDistNormed;
                s.waterOverSurfacePos = vis.WaterOverSurfacePos;
#endif

#if MP4 || TURBO
                s.activeEffects = vis.ActiveEffects;
                s.turboActive = vis.TurboActive;
                s.turboPercent = vis.TurboPercent;
#endif
#if MP4
                s.gearPercent = vis.GearPercent;
#endif

#if TMNEXT
                s.reactorTimer = VehicleState::GetReactorFinalTimer(vis);
                s.lastTurbo = int(VehicleState::GetLastTurboLevel(vis));
                s.lastTurboName = tostring(VehicleState::GetLastTurboLevel(vis));
                s.cruiseSpeed = VehicleState::GetCruiseDisplaySpeed(vis);
                s.vehicleType = int(VehicleState::GetVehicleType(vis));
                s.vehicleTypeName = tostring(VehicleState::GetVehicleType(vis));
#else
                s.reactorTimer = 0.0f;
                s.lastTurbo = 0;
                s.lastTurboName = "unavailable";
                s.cruiseSpeed = 0;
                s.vehicleType = 0;
                s.vehicleTypeName = "unavailable";
#endif

                bool finished = false;
#if DEPENDENCY_MLFEEDRACEDATA
                auto rd = MLFeed::GetRaceData_V4();
                if (rd !is null) {
                    auto lp = rd.LocalPlayer;
                    if (lp !is null) {
                        finished = lp.CpCount >= int(rd.CPsToFinish);
                    }
                }
#endif
                s.finished = finished;
                s.steerAngFL = vis.FLSteerAngle;
                s.steerAngFR = vis.FRSteerAngle;
                s.steerAngRL = vis.RLSteerAngle;
                s.steerAngRR = vis.RRSteerAngle;
                s.wheelRotFL = vis.FLWheelRot;
                s.wheelRotFR = vis.FRWheelRot;
                s.wheelRotRL = vis.RLWheelRot;
                s.wheelRotRR = vis.RRWheelRot;
                s.wheelRotSpeedFL = vis.FLWheelRotSpeed;
                s.wheelRotSpeedFR = vis.FRWheelRotSpeed;
                s.wheelRotSpeedRL = vis.RLWheelRotSpeed;
                s.wheelRotSpeedRR = vis.RRWheelRotSpeed;
                s.damperFL = vis.FLDamperLen;
                s.damperFR = vis.FRDamperLen;
                s.damperRL = vis.RLDamperLen;
                s.damperRR = vis.RRDamperLen;
                s.slipFL = vis.FLSlipCoef;
                s.slipFR = vis.FRSlipCoef;
                s.slipRL = vis.RLSlipCoef;
                s.slipRR = vis.RRSlipCoef;
                s.matFL = int(vis.FLGroundContactMaterial);
                s.matFR = int(vis.FRGroundContactMaterial);
                s.matRL = int(vis.RLGroundContactMaterial);
                s.matRR = int(vis.RRGroundContactMaterial);

#if TMNEXT
                s.dirtFL = VehicleState::GetWheelDirt(vis, 0);
                s.dirtFR = VehicleState::GetWheelDirt(vis, 1);
                s.dirtRL = VehicleState::GetWheelDirt(vis, 2);
                s.dirtRR = VehicleState::GetWheelDirt(vis, 3);
                s.fallFL = int(VehicleState::GetWheelFalling(vis, 0));
                s.fallFR = int(VehicleState::GetWheelFalling(vis, 1));
                s.fallRL = int(VehicleState::GetWheelFalling(vis, 2));
                s.fallRR = int(VehicleState::GetWheelFalling(vis, 3));
                s.fallNameFL = tostring(VehicleState::GetWheelFalling(vis, 0));
                s.fallNameFR = tostring(VehicleState::GetWheelFalling(vis, 1));
                s.fallNameRL = tostring(VehicleState::GetWheelFalling(vis, 2));
                s.fallNameRR = tostring(VehicleState::GetWheelFalling(vis, 3));
                s.breakNormedFL = vis.FLBreakNormedCoef;
                s.breakNormedFR = vis.FRBreakNormedCoef;
                s.breakNormedRL = vis.RLBreakNormedCoef;
                s.breakNormedRR = vis.RRBreakNormedCoef;
                s.icingFL = vis.FLIcing01;
                s.icingFR = vis.FRIcing01;
                s.icingRL = vis.RLIcing01;
                s.icingRR = vis.RRIcing01;
                s.tireWearFL = vis.FLTireWear01;
                s.tireWearFR = vis.FRTireWear01;
                s.tireWearRL = vis.RLTireWear01;
                s.tireWearRR = vis.RRTireWear01;
#else
                s.dirtFL = 0.0f;
                s.dirtFR = 0.0f;
                s.dirtRL = 0.0f;
                s.dirtRR = 0.0f;
                s.fallFL = 0;
                s.fallFR = 0;
                s.fallRL = 0;
                s.fallRR = 0;
                s.fallNameFL = "unavailable";
                s.fallNameFR = "unavailable";
                s.fallNameRL = "unavailable";
                s.fallNameRR = "unavailable";
#endif

#if MP4 || TURBO || FOREVER
                s.contactFL = vis.FLGroundContact;
                s.contactFR = vis.FRGroundContact;
                s.contactRL = vis.RLGroundContact;
                s.contactRR = vis.RRGroundContact;
#endif
#if MP4
                s.wetFL = vis.FLIsWet;
                s.wetFR = vis.FRIsWet;
                s.wetRL = vis.RLIsWet;
                s.wetRR = vis.RRIsWet;
#endif

                @g_latest = s;
                g_ready = true;
#else
                @g_latest = null;
                g_ready = false;
                g_unavailableReason = "vehicle_state_dependency_unavailable";
#endif
            }

            Json::Value GetJson() {
                if (!g_ready || g_latest is null) {
                    return Unavailable(g_unavailableReason);
                }
                return g_latest.ToJson();
            }
        }
    }
}
