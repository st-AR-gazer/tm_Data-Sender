namespace DataSender {
    namespace Sources {
        namespace RaceData {
            Json::Value MakeSnapshot() {
                Json::Value root = Json::Object();

#if DEPENDENCY_MLFEEDRACEDATA
                auto rd = MLFeed::GetRaceData_V4();
                root["available"] = false;
                if (rd is null) {
                    root["reason"] = "no_race_data";
                    return root;
                }

                root["available"] = true;
                root["map"] = rd.Map;
                root["gameTime"] = MLFeed::GameTime;
                root["cpCount"] = rd.CPCount;
                root["lapCount"] = rd.LapCount_Accurate;
                root["spawnCount"] = rd.SpawnCounter;
                Json::Value playersArr;
                playersArr = Json::Array();

                for (uint i = 0; i < rd.SortedPlayers_Race.Length; i++) {
                    auto p = cast<MLFeed::PlayerCpInfo_V4>(rd.SortedPlayers_Race[i]);
                    if (p is null) continue;

                    Json::Value pj = Json::Object();
                    pj["name"] = p.Name;
                    pj["login"] = p.Login;
                    pj["wsid"] = p.WebServicesUserId;
                    pj["cp"] = p.CpCount;
                    pj["lastCpMs"] = p.LastCpTime;
                    pj["bestMs"] = p.BestTime;
                    pj["raceRank"] = p.RaceRank;
                    pj["taRank"] = p.TaRank;
                    pj["respawns"] = p.NbRespawnsRequested;
                    playersArr.Add(pj);
                }
                root["players"] = playersArr;
#else
                root["available"] = false;
                root["reason"] = "mlfeed_race_data_dependency_unavailable";
#endif
                return root;
            }
        }
    }
}
