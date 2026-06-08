namespace DataSender {
    namespace Sources {
        namespace MLFeedCpInfoSource {
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
                root["gameTime"] = UIntJson(MLFeed::GameTime);
                root["cpCount"] = UIntJson(rd.CPCount);
                root["cpsToFinish"] = UIntJson(rd.CPsToFinish);
                root["lapCount"] = UIntJson(rd.LapCount_Accurate);
                root["spawnCount"] = UIntJson(rd.SpawnCounter);

                if (rd.LocalPlayer !is null) {
                    root["localPlayer"] = PlayerJson(rd.LocalPlayer);
                }

                Json::Value racePlayers = PlayerArrayJson(rd.SortedPlayers_Race);
                Json::Value raceRespawnPlayers = PlayerArrayJson(rd.SortedPlayers_Race_Respawns);
                Json::Value timeAttackPlayers = PlayerArrayJson(rd.SortedPlayers_TimeAttack);

                root["players"] = racePlayers;

                Json::Value sortedPlayers = Json::Object();
                sortedPlayers["race"] = racePlayers;
                sortedPlayers["raceRespawns"] = raceRespawnPlayers;
                sortedPlayers["timeAttack"] = timeAttackPlayers;
                root["sortedPlayers"] = sortedPlayers;
#else
                root["available"] = false;
                root["reason"] = "mlfeed_race_data_dependency_unavailable";
#endif
                return root;
            }

#if DEPENDENCY_MLFEEDRACEDATA
            Json::Value PlayerArrayJson(const array<MLFeed::PlayerCpInfo_V2@>@ players) {
                Json::Value arr = Json::Array();
                if (players is null) return arr;

                for (uint i = 0; i < players.Length; i++) {
                    auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
                    if (player is null) continue;
                    Json::Value item = PlayerJson(player);
                    item["order"] = UIntJson(i + 1);
                    arr.Add(item);
                }
                return arr;
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

            Json::Value PlayerJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = PlayerIdentityJson(player);
                if (player is null) return root;

                root["summary"] = player.ToString();
                root["isLocalPlayer"] = player.IsLocalPlayer;
                root["isMVP"] = player.IsMVP;
                root["isSpawned"] = player.IsSpawned;
                root["isFinished"] = player.IsFinished;
                root["playerIsRacing"] = player.PlayerIsRacing;
                root["eliminated"] = player.Eliminated;
                root["requestsSpectate"] = player.RequestsSpectate;
                root["spawnStatus"] = tostring(player.SpawnStatus);
                root["spawnStatusValue"] = int(player.SpawnStatus);
                root["spawnIndex"] = UIntJson(player.SpawnIndex);
                root["spawnCount"] = UIntJson(player.SpawnCount);
                root["startTime"] = UIntJson(player.StartTime);
                root["currentLap"] = UIntJson(player.CurrentLap);
                root["updateNonce"] = UIntJson(player.UpdateNonce);
                root["firstSeen"] = UIntJson(player.FirstSeen);
                root["cpCount"] = player.CpCount;
                root["cpTimes"] = IntArrayJson(player.CpTimes);
                root["lastCpTime"] = player.LastCpTime;
                root["finishTime"] = player.FinishTime;
                root["lastCpOrRespawnTime"] = player.LastCpOrRespawnTime;
                root["lastTheoreticalCpTime"] = player.LastTheoreticalCpTime;
                root["currentRaceTime"] = player.CurrentRaceTime;
                root["currentRaceTimeRaw"] = player.CurrentRaceTimeRaw;
                root["theoreticalRaceTime"] = player.TheoreticalRaceTime;
                root["bestTime"] = player.BestTime;
                root["bestRaceTimes"] = UIntArrayJson(player.BestRaceTimes);
                root["bestLapTimes"] = UIntArrayJson(player.BestLapTimes);
                root["nbRespawnsRequested"] = UIntJson(player.NbRespawnsRequested);
                root["lastRespawnCheckpoint"] = UIntJson(player.LastRespawnCheckpoint);
                root["lastRespawnRaceTime"] = UIntJson(player.LastRespawnRaceTime);
                root["timeLostToRespawns"] = UIntJson(player.TimeLostToRespawns);
                root["timeLostToRespawnByCp"] = IntArrayJson(player.TimeLostToRespawnByCp);
                root["nbRespawnsByCp"] = IntArrayJson(player.NbRespawnsByCp);
                root["respawnTimes"] = IntArrayJson(player.RespawnTimes);
                root["raceRank"] = UIntJson(player.RaceRank);
                root["raceRespawnRank"] = UIntJson(player.RaceRespawnRank);
                root["taRank"] = UIntJson(player.TaRank);
                root["roundPoints"] = player.RoundPoints;
                root["points"] = player.Points;
                root["teamNum"] = player.TeamNum;
                root["latencyEstimate"] = player.latencyEstimate;
                root["raceProgression"] = Int2Json(player.RaceProgression);
                root["raceProgressionHistory"] = IntArrayValueJson(player.RaceProgressionHistory);
                root["royalTAHasFinished"] = player.RoyalTA_HasFinished;
                root["royalTASegmentsFinished"] = player.RoyalTA_SegmentsFinished;
                if (player.KoState !is null) {
                    root["koState"] = KoStateJson(player.KoState);
                }
                return root;
            }

            Json::Value KoStateJson(const MLFeed::KoPlayerState@ state) {
                Json::Value root = Json::Object();
                if (state is null) return root;

                root["name"] = state.name;
                root["isAlive"] = state.isAlive;
                root["isDNF"] = state.isDNF;
                return root;
            }

            Json::Value MwIdJson(const MwId &in id) {
                Json::Value root = Json::Object();
                root["value"] = UIntJson(id.Value);
                root["name"] = id.GetName();
                return root;
            }

            Json::Value Int2Json(const int2 &in value) {
                Json::Value root = Json::Object();
                root["x"] = value.x;
                root["y"] = value.y;
                root["points"] = value.x;
                root["time"] = value.y;
                return root;
            }

            Json::Value IntArrayJson(const array<int>@ values) {
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

            Json::Value UIntArrayJson(const array<uint>@ values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

                for (uint i = 0; i < values.Length; i++) {
                    arr.Add(UIntJson(values[i]));
                }
                return arr;
            }

            int64 UIntJson(uint value) {
                return DataSender::Toolkit::JsonCounter(uint64(value));
            }
#endif
        }
    }
}
