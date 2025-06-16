namespace VState {

    class Snapshot {
        uint  t;             // Time::Now
        float spd;           // speed m/s
        vec3  pos;           // position
        float steer;
        float throttle;
        float brake;
        bool  finished;
        float accel;         // derived
        float jerk;          // derived
        float rpm;
        vec3  reactorAC;
        float groundDist;
        bool  groundContact;
        bool  reactorGround;
        int   gear;

        float steerAngFL, steerAngFR,
              wheelRotFL, wheelRotFR;

        float damperFL, damperFR, damperRL, damperRR;
        float slipFL,   slipFR,   slipRL,  slipRR;

        int matFL, matFR, matRL, matRR;

        Json::Value ToJson() const {
            Json::Value o = Json::Object();
            o["t"]   = int(t);
            o["spd"] = spd;

            Json::Value p = Json::Array();
            p.Add(pos.x); p.Add(pos.y); p.Add(pos.z);
            o["pos"] = p;

            o["steer"]    = steer;
            o["throttle"] = throttle;
            o["brake"]    = brake;
            o["finished"] = finished;
            o["accel"]    = accel;
            o["jerk"]     = jerk;
            o["rpm"]      = rpm;

            Json::Value rac = Json::Array();
            rac.Add(reactorAC.x); rac.Add(reactorAC.y); rac.Add(reactorAC.z);
            o["reactorAC"] = rac;

            o["groundDist"]    = groundDist;
            o["groundContact"] = groundContact;
            o["reactorGnd"]    = reactorGround;
            o["gear"]          = gear;

            Json::Value fl = Json::Object();
                        fl["steerAng"]=steerAngFL;
                        fl["rot"]=wheelRotFL;
                        fl["damper"]=damperFL;
                        fl["slip"]=slipFL;
                        fl["mat"]=matFL;

            Json::Value fr = Json::Object();
                        fr["steerAng"]=steerAngFR;
                        fr["rot"]=wheelRotFR;
                        fr["damper"]=damperFR;
                        fr["slip"]=slipFR;
                        fr["mat"]=matFR;
                        
            Json::Value rl = Json::Object();
                        rl["damper"]=damperRL;
                        rl["slip"]=slipRL;
                        rl["mat"]=matRL;
                        
            Json::Value rr = Json::Object();
                        rr["damper"]=damperRR;
                        rr["slip"]=slipRR;
                        rr["mat"]=matRR;

            o["FL"] = fl; o["FR"] = fr; o["RL"] = rl; o["RR"] = rr;
            return o;
        }
    }

    Snapshot@ g_latest    = null;
    float     g_prevSpeed = 0.0f;
    float     g_prevAccel = 0.0f;
    bool      g_ready     = false;

    void Update(float dt) {
        if (dt <= 0) dt = 0.016f;

        CSceneVehicleVisState@ vis = VehicleState::ViewingPlayerState();
        if (vis is null) return;

        Snapshot s;
        s.t         = Time::Now;

        s.pos       = vis.Position;
        float speed = vis.WorldVel.Length();
        s.spd       = speed;

        s.accel     = (speed - g_prevSpeed) / dt;
        s.jerk      = (s.accel - g_prevAccel) / dt;
        g_prevSpeed = speed;
        g_prevAccel = s.accel;

        s.steer     = vis.InputSteer;
        s.throttle  = vis.InputGasPedal;
        s.brake     = vis.InputBrakePedal;

        s.groundContact = vis.IsGroundContact;
        s.reactorGround = vis.IsReactorGroundMode;
        s.groundDist    = vis.GroundDist;
        s.reactorAC     = vis.ReactorAirControl;
        s.gear          = vis.CurGear;
        s.rpm           = VehicleState::GetRPM(vis);

        bool finished = false;
        auto rd = MLFeed::GetRaceData_V4();
        if (rd !is null) {
            auto lp = rd.LocalPlayer;
            if (lp !is null) {
                finished = lp.CpCount >= int(rd.CPsToFinish);
            }
        }
        s.finished = finished;

        s.steerAngFL = vis.FLSteerAngle;
        s.steerAngFR = vis.FRSteerAngle;

        s.wheelRotFL = vis.FLWheelRot;
        s.wheelRotFR = vis.FRWheelRot;

        s.damperFL   = vis.FLDamperLen;
        s.damperFR   = vis.FRDamperLen;
        s.damperRL   = vis.RLDamperLen;
        s.damperRR   = vis.RRDamperLen;

        s.slipFL     = vis.FLSlipCoef;
        s.slipFR     = vis.FRSlipCoef;
        s.slipRL     = vis.RLSlipCoef;
        s.slipRR     = vis.RRSlipCoef;

        s.matFL      = int(vis.FLGroundContactMaterial);
        s.matFR      = int(vis.FRGroundContactMaterial);
        s.matRL      = int(vis.RLGroundContactMaterial);
        s.matRR      = int(vis.RRGroundContactMaterial);

        @g_latest = s;
        g_ready   = true;
    }
    
    Json::Value GetJson() {
        if (!g_ready || g_latest is null) {
            Json::Value empty;
            return empty;
        }
        return g_latest.ToJson();
    }

}

