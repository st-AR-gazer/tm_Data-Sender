namespace DataSender {
    namespace Sources {
        namespace MLFeedRaceDataSource {
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
                root["localPlayersName"] = MLFeed::LocalPlayersName;
                root["localPlayersLoginIdValue"] = DataSender::Sources::Helpers::UIntJson(MLFeed::LocalPlayersLoginIdValue);
                root["cpCount"] = DataSender::Sources::Helpers::UIntJson(rd.CPCount);
                root["cpsToFinish"] = DataSender::Sources::Helpers::UIntJson(rd.CPsToFinish);
                root["lapCount"] = DataSender::Sources::Helpers::UIntJson(rd.LapCount_Accurate);
                root["lapCountRaw"] = DataSender::Sources::Helpers::UIntJson(rd.LapCount);
                root["lapsNb"] = rd.LapsNb;
                root["spawnCount"] = DataSender::Sources::Helpers::UIntJson(rd.SpawnCounter);
                root["updateNonce"] = DataSender::Sources::Helpers::UIntJson(rd.UpdateNonce);
                root["lastRecordTime"] = rd.LastRecordTime;
                root["rules"] = RulesJson(rd);
                root["warmup"] = WarmupJson(rd);
                root["playersLeft"] = PlayersLeftJson(rd);
                root["cotdQualification"] = CotdQualificationJson(rd);
                if (rd.LocalPlayer !is null) {
                    root["localPlayer"] = PlayerRefJson(rd.LocalPlayer);
                }
                Json::Value racePlayers = PlayerRefArrayJson(rd.SortedPlayers_Race);
                Json::Value raceRespawnPlayers = PlayerRefArrayJson(rd.SortedPlayers_Race_Respawns);
                Json::Value timeAttackPlayers = PlayerRefArrayJson(rd.SortedPlayers_TimeAttack);
                root["players"] = racePlayers;
                Json::Value sortedPlayers = Json::Object();
                sortedPlayers["race"] = racePlayers;
                sortedPlayers["raceRespawns"] = raceRespawnPlayers;
                sortedPlayers["timeAttack"] = timeAttackPlayers;
                root["sortedPlayers"] = sortedPlayers;
                Json::Value playerCounts = Json::Object();
                playerCounts["race"] = DataSender::Sources::Helpers::UIntJson(rd.SortedPlayers_Race.Length);
                playerCounts["raceRespawns"] = DataSender::Sources::Helpers::UIntJson(rd.SortedPlayers_Race_Respawns.Length);
                playerCounts["timeAttack"] = DataSender::Sources::Helpers::UIntJson(rd.SortedPlayers_TimeAttack.Length);
                root["playerCounts"] = playerCounts;
#else
                root["available"] = false;
                root["reason"] = "mlfeed_race_data_dependency_unavailable";
#endif
                return root;
            }

#if DEPENDENCY_MLFEEDRACEDATA
            Json::Value RulesJson(const MLFeed::HookRaceStatsEventsBase_V4@ rd) {
                Json::Value root = Json::Object();
                if (rd is null) return root;

                root["gameTime"] = rd.Rules_GameTime;
                root["startTime"] = rd.Rules_StartTime;
                root["endTime"] = rd.Rules_EndTime;
                root["millisSinceStart"] = rd.Rules_MillisSinceStart;
                root["timeElapsed"] = rd.Rules_TimeElapsed;
                root["timeRemaining"] = rd.Rules_TimeRemaining;
                return root;
            }

            Json::Value WarmupJson(const MLFeed::HookRaceStatsEventsBase_V4@ rd) {
                Json::Value root = Json::Object();
                if (rd is null) return root;

                root["active"] = rd.WarmupActive;
                root["endTime"] = rd.WarmupEndTime;
                return root;
            }

            Json::Value PlayersLeftJson(const MLFeed::HookRaceStatsEventsBase_V4@ rd) {
                Json::Value root = Json::Object();
                if (rd is null) return root;

                root["batchNumber"] = DataSender::Sources::Helpers::UIntJson(rd.PlayersLeft_BatchNumber);
                root["names"] = DataSender::Sources::Helpers::StringArrayJson(rd.PlayersLeftThisBatch);
                root["loginIdValues"] = DataSender::Sources::Helpers::UIntArrayJson(rd.PlayersLeftThisBatch_LoginIdValues);
                return root;
            }

            Json::Value CotdQualificationJson(const MLFeed::HookRaceStatsEventsBase_V4@ rd) {
                Json::Value root = Json::Object();
                if (rd is null) return root;

                root["localRaceTime"] = rd.COTDQ_LocalRaceTime;
                root["apiRaceTime"] = rd.COTDQ_APIRaceTime;
                root["rank"] = rd.COTDQ_Rank;
                root["joinTime"] = rd.COTDQ_QualificationsJoinTime;
                root["stage"] = tostring(rd.COTDQ_QualificationsProgress);
                root["stageValue"] = int(rd.COTDQ_QualificationsProgress);
                root["isSynchronizingRecord"] = rd.COTDQ_IsSynchronizingRecord;
                root["updateNonce"] = rd.COTDQ_UpdateNonce;
                return root;
            }

            Json::Value PlayerRefArrayJson(const array<MLFeed::PlayerCpInfo_V2@> @players) {
                Json::Value arr = Json::Array();
                if (players is null) return arr;

                for (uint i = 0; i < players.Length; i++) {
                    auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
                    if (player is null) continue;
                    Json::Value item = PlayerRefJson(player);
                    item["order"] = DataSender::Sources::Helpers::UIntJson(i + 1);
                    arr.Add(item);
                }
                return arr;
            }

            Json::Value PlayerRefJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = Json::Object();
                if (player is null) return root;

                root = DataSender::Sources::Helpers::PlayerIdentityJson(player);
                root["cpCount"] = player.CpCount;
                root["raceRank"] = DataSender::Sources::Helpers::UIntJson(player.RaceRank);
                root["raceRespawnRank"] = DataSender::Sources::Helpers::UIntJson(player.RaceRespawnRank);
                root["taRank"] = DataSender::Sources::Helpers::UIntJson(player.TaRank);
                return root;
            }
#endif
        }
    }
}
