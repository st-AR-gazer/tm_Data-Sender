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
                root["gameTime"] = UIntJson(MLFeed::GameTime);
                root["localPlayersName"] = MLFeed::LocalPlayersName;
                root["localPlayersLoginIdValue"] = UIntJson(MLFeed::LocalPlayersLoginIdValue);
                root["cpCount"] = UIntJson(rd.CPCount);
                root["cpsToFinish"] = UIntJson(rd.CPsToFinish);
                root["lapCount"] = UIntJson(rd.LapCount_Accurate);
                root["lapCountRaw"] = UIntJson(rd.LapCount);
                root["lapsNb"] = rd.LapsNb;
                root["spawnCount"] = UIntJson(rd.SpawnCounter);
                root["updateNonce"] = UIntJson(rd.UpdateNonce);
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
                playerCounts["race"] = UIntJson(rd.SortedPlayers_Race.Length);
                playerCounts["raceRespawns"] = UIntJson(rd.SortedPlayers_Race_Respawns.Length);
                playerCounts["timeAttack"] = UIntJson(rd.SortedPlayers_TimeAttack.Length);
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

                root["batchNumber"] = UIntJson(rd.PlayersLeft_BatchNumber);
                root["names"] = StringArrayJson(rd.PlayersLeftThisBatch);
                root["loginIdValues"] = UIntArrayJson(rd.PlayersLeftThisBatch_LoginIdValues);
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

            Json::Value PlayerRefArrayJson(const array<MLFeed::PlayerCpInfo_V2@>@ players) {
                Json::Value arr = Json::Array();
                if (players is null) return arr;

                for (uint i = 0; i < players.Length; i++) {
                    auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
                    if (player is null) continue;
                    Json::Value item = PlayerRefJson(player);
                    item["order"] = UIntJson(i + 1);
                    arr.Add(item);
                }
                return arr;
            }

            Json::Value PlayerRefJson(const MLFeed::PlayerCpInfo_V4@ player) {
                Json::Value root = Json::Object();
                if (player is null) return root;

                root["name"] = player.Name;
                root["login"] = player.Login;
                root["wsid"] = player.WebServicesUserId;
                root["loginMwId"] = MwIdJson(player.LoginMwId);
                root["nameMwId"] = MwIdJson(player.NameMwId);
                root["cpCount"] = player.CpCount;
                root["raceRank"] = UIntJson(player.RaceRank);
                root["raceRespawnRank"] = UIntJson(player.RaceRespawnRank);
                root["taRank"] = UIntJson(player.TaRank);
                return root;
            }

            Json::Value MwIdJson(const MwId &in id) {
                Json::Value root = Json::Object();
                root["value"] = UIntJson(id.Value);
                root["name"] = id.GetName();
                return root;
            }

            Json::Value StringArrayJson(const array<string>@ values) {
                Json::Value arr = Json::Array();
                if (values is null) return arr;

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
