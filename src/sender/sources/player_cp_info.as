namespace DataSender {
    namespace Sources {
        namespace PlayerCpInfo {
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
                root["cpsToFinish"] = rd.CPsToFinish;
                root["lapCount"] = rd.LapCount_Accurate;
                root["spawnCount"] = rd.SpawnCounter;
                if (rd.LocalPlayer !is null) {
                    root["localPlayer"] = PlayerIdentityJson(rd.LocalPlayer);
                }
                Json::Value players = Json::Array();
                for (uint i = 0; i < rd.SortedPlayers_Race.Length; i++) {
                    auto player = cast<MLFeed::PlayerCpInfo_V4>(rd.SortedPlayers_Race[i]);
                    if (player is null) continue;
                    players.Add(PlayerJson(player));
                }
                root["players"] = players;
#else
                root["available"] = false;
                root["reason"] = "mlfeed_race_data_dependency_unavailable";
#endif
                return root;
            }

#if DEPENDENCY_MLFEEDRACEDATA
            Json::Value PlayerIdentityJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = Json::Object();
                if (player is null) return root;

                root["name"] = player.Name;
                root["login"] = player.Login;
                root["wsid"] = player.WebServicesUserId;
                return root;
            }

            Json::Value PlayerJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = PlayerIdentityJson(player);
                if (player is null) return root;

                root["summary"] = player.ToString();
                root["isLocalPlayer"] = player.IsLocalPlayer;
                root["isMVP"] = player.IsMVP;
                root["isSpawned"] = player.IsSpawned;
                root["isFinished"] = player.IsFinished;
                root["spawnStatus"] = tostring(player.SpawnStatus);
                root["spawnStatusValue"] = int(player.SpawnStatus);
                root["spawnIndex"] = int(player.SpawnIndex);
                root["startTime"] = int(player.StartTime);
                root["currentLap"] = int(player.CurrentLap);
                root["cpCount"] = player.CpCount;
                root["cpTimes"] = IntArrayJson(player.CpTimes);
                root["lastCpTime"] = player.LastCpTime;
                root["lastCpOrRespawnTime"] = player.LastCpOrRespawnTime;
                root["lastTheoreticalCpTime"] = player.LastTheoreticalCpTime;
                root["currentRaceTime"] = player.CurrentRaceTime;
                root["currentRaceTimeRaw"] = player.CurrentRaceTimeRaw;
                root["theoreticalRaceTime"] = player.TheoreticalRaceTime;
                root["bestTime"] = player.BestTime;
                root["bestRaceTimes"] = UIntArrayJson(player.BestRaceTimes);
                root["bestLapTimes"] = UIntArrayJson(player.BestLapTimes);
                root["nbRespawnsRequested"] = int(player.NbRespawnsRequested);
                root["lastRespawnCheckpoint"] = int(player.LastRespawnCheckpoint);
                root["lastRespawnRaceTime"] = int(player.LastRespawnRaceTime);
                root["timeLostToRespawns"] = int(player.TimeLostToRespawns);
                root["timeLostToRespawnByCp"] = IntArrayJson(player.TimeLostToRespawnByCp);
                root["raceRank"] = int(player.RaceRank);
                root["raceRespawnRank"] = int(player.RaceRespawnRank);
                root["taRank"] = int(player.TaRank);
                root["roundPoints"] = player.RoundPoints;
                root["points"] = player.Points;
                root["teamNum"] = player.TeamNum;
                root["latencyEstimate"] = player.latencyEstimate;
                return root;
            }

            Json::Value IntArrayJson(const array<int> @values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(values[i]);
                }
                return arr;
            }

            Json::Value UIntArrayJson(const array<uint> @values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(int(values[i]));
                }
                return arr;
            }
#endif
        }
    }
}
