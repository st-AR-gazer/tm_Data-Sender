namespace DataSender {
    namespace App {
        void RenderGeneralSettingsUI() {
            bool open = UI::BeginChild("##data-sender-settings-general", vec2(0, 0), false);
            if (open) {
                S_WindowOpen = UI::Checkbox("Show main window", S_WindowOpen);
                S_HideWithGame = UI::Checkbox("Hide with game UI", S_HideWithGame);
                S_HideWithOP = UI::Checkbox("Hide with Openplanet UI", S_HideWithOP);

                UI::Separator();
                DataSender::Sender::Service::S_AutoStart = UI::Checkbox(
                    "Start service on plugin load",
                    DataSender::Sender::Service::S_AutoStart
                );
                DataSender::Sender::Service::S_EnableRaceData = UI::Checkbox(
                    "Race data source",
                    DataSender::Sender::Service::S_EnableRaceData
                );
                DataSender::Sender::Service::S_EnableVehicleState = UI::Checkbox(
                    "Vehicle state source",
                    DataSender::Sender::Service::S_EnableVehicleState
                );

                int raceDataInterval = int(DataSender::Sender::Service::S_RaceDataIntervalMs);
                UI::SetNextItemWidth(180.0f);
                raceDataInterval = UI::SliderInt("Race data interval (ms)", raceDataInterval, 1, 1000);
                DataSender::Sender::Service::S_RaceDataIntervalMs = uint(raceDataInterval);

                int vehicleStateInterval = int(DataSender::Sender::Service::S_VehicleStateIntervalMs);
                UI::SetNextItemWidth(180.0f);
                vehicleStateInterval = UI::SliderInt("Vehicle state interval (ms)", vehicleStateInterval, 1, 1000);
                DataSender::Sender::Service::S_VehicleStateIntervalMs = uint(vehicleStateInterval);
            }
            UI::EndChild();
        }

        void RenderLoggingSettingsUI() {
            bool open = UI::BeginChild("##data-sender-settings-logging", vec2(0, 0), false);
            if (open) {
                logging::RenderSettingsUI("data-sender-logging");
            }
            UI::EndChild();
        }
    }
}
