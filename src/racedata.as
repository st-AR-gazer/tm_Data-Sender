Json::Value MakeSnapshot() {
    auto rd = MLFeed::GetRaceData_V4();
    Json::Value root = Json::Object();

    root["map"]        = rd.Map;
    root["gameTime"]   = MLFeed::GameTime;
    root["cpCount"]    = rd.CPCount;
    root["lapCount"]   = rd.LapCount_Accurate;
    root["spawnCount"] = rd.SpawnCounter;

    Json::Value playersArr;

    playersArr = Json::Array();

    for (uint i = 0; i < rd.SortedPlayers_Race.Length; i++) {
        auto p = cast<MLFeed::PlayerCpInfo_V4>(rd.SortedPlayers_Race[i]);
        Json::Value pj = Json::Object();

        pj["name"]     = p.Name;
        pj["login"]    = p.Login;
        pj["wsid"]     = p.WebServicesUserId;
        pj["cp"]       = p.CpCount;
        pj["lastCpMs"] = p.LastCpTime;
        pj["bestMs"]   = p.BestTime;
        pj["raceRank"] = p.RaceRank;
        pj["taRank"]   = p.TaRank;
        pj["respawns"] = p.NbRespawnsRequested;

        playersArr.Add(pj);
    }
    root["players"] = playersArr;
    return root;
}
