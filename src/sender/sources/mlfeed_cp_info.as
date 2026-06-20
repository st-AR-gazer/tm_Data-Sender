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
                root["gameTime"] = DataSender::Sources::Helpers::UIntJson(MLFeed::GameTime);
                root["cpCount"] = DataSender::Sources::Helpers::UIntJson(rd.CPCount);
                root["cpsToFinish"] = DataSender::Sources::Helpers::UIntJson(rd.CPsToFinish);
                root["lapCount"] = DataSender::Sources::Helpers::UIntJson(rd.LapCount_Accurate);
                root["spawnCount"] = DataSender::Sources::Helpers::UIntJson(rd.SpawnCounter);
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
            Json::Value PlayerArrayJson(const array<MLFeed::PlayerCpInfo_V2@> @players) {
                Json::Value arr = Json::Array();
                if (players is null) return arr;

                for (uint i = 0; i < players.Length; i++) {
                    auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
                    if (player is null) continue;
                    Json::Value item = PlayerJson(player);
                    item["order"] = DataSender::Sources::Helpers::UIntJson(i + 1);
                    arr.Add(item);
                }
                return arr;
            }

            Json::Value PlayerJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = DataSender::Sources::Helpers::PlayerIdentityJson(player);
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
                root["spawnIndex"] = DataSender::Sources::Helpers::UIntJson(player.SpawnIndex);
                root["spawnCount"] = DataSender::Sources::Helpers::UIntJson(player.SpawnCount);
                root["startTime"] = DataSender::Sources::Helpers::UIntJson(player.StartTime);
                root["currentLap"] = DataSender::Sources::Helpers::UIntJson(player.CurrentLap);
                root["updateNonce"] = DataSender::Sources::Helpers::UIntJson(player.UpdateNonce);
                root["firstSeen"] = DataSender::Sources::Helpers::UIntJson(player.FirstSeen);
                root["cpCount"] = player.CpCount;
                root["cpTimes"] = DataSender::Sources::Helpers::IntArrayJson(player.CpTimes);
                root["lastCpTime"] = player.LastCpTime;
                root["finishTime"] = player.FinishTime;
                root["lastCpOrRespawnTime"] = player.LastCpOrRespawnTime;
                root["lastTheoreticalCpTime"] = player.LastTheoreticalCpTime;
                root["currentRaceTime"] = player.CurrentRaceTime;
                root["currentRaceTimeRaw"] = player.CurrentRaceTimeRaw;
                root["theoreticalRaceTime"] = player.TheoreticalRaceTime;
                root["bestTime"] = player.BestTime;
                root["bestRaceTimes"] = DataSender::Sources::Helpers::UIntArrayJson(player.BestRaceTimes);
                root["bestLapTimes"] = DataSender::Sources::Helpers::UIntArrayJson(player.BestLapTimes);
                root["nbRespawnsRequested"] = DataSender::Sources::Helpers::UIntJson(player.NbRespawnsRequested);
                root["lastRespawnCheckpoint"] = DataSender::Sources::Helpers::UIntJson(player.LastRespawnCheckpoint);
                root["lastRespawnRaceTime"] = DataSender::Sources::Helpers::UIntJson(player.LastRespawnRaceTime);
                root["timeLostToRespawns"] = DataSender::Sources::Helpers::UIntJson(player.TimeLostToRespawns);
                root["timeLostToRespawnByCp"] = DataSender::Sources::Helpers::IntArrayJson(player.TimeLostToRespawnByCp);
                root["nbRespawnsByCp"] = DataSender::Sources::Helpers::IntArrayJson(player.NbRespawnsByCp);
                root["respawnTimes"] = DataSender::Sources::Helpers::IntArrayJson(player.RespawnTimes);
                root["raceRank"] = DataSender::Sources::Helpers::UIntJson(player.RaceRank);
                root["raceRespawnRank"] = DataSender::Sources::Helpers::UIntJson(player.RaceRespawnRank);
                root["taRank"] = DataSender::Sources::Helpers::UIntJson(player.TaRank);
                root["roundPoints"] = player.RoundPoints;
                root["points"] = player.Points;
                root["teamNum"] = player.TeamNum;
                root["latencyEstimate"] = player.latencyEstimate;
                root["raceProgression"] = DataSender::Sources::Helpers::RaceProgressionJson(player.RaceProgression);
                root["raceProgressionHistory"] = DataSender::Sources::Helpers::IntArrayValueJson(player.RaceProgressionHistory);
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

#endif
        }
    }
}
