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
                DataSender::Server::Tcp::S_Enabled = UI::Checkbox(
                    "TCP server",
                    DataSender::Server::Tcp::S_Enabled
                );
                UI::TextDisabled("Host: " + DataSender::Server::Tcp::S_Host);
                int tcpPort = DataSender::Server::Tcp::S_Port;
                UI::SetNextItemWidth(180.0f);
                tcpPort = UI::InputInt("TCP port", tcpPort);
                DataSender::Server::Tcp::S_Port = Math::Clamp(tcpPort, 1, 65535);
                int tcpBroadcastInterval = int(DataSender::Server::Tcp::S_BroadcastIntervalMs);
                UI::SetNextItemWidth(180.0f);
                tcpBroadcastInterval = UI::SliderInt("TCP broadcast interval (ms)", tcpBroadcastInterval, 16, 1000);
                DataSender::Server::Tcp::S_BroadcastIntervalMs = uint(tcpBroadcastInterval);

                int tcpMaxClients = DataSender::Server::Tcp::S_MaxClients;
                UI::SetNextItemWidth(180.0f);
                tcpMaxClients = UI::SliderInt("TCP max clients", tcpMaxClients, 1, 64);
                DataSender::Server::Tcp::S_MaxClients = tcpMaxClients;

                for (uint i = 0; i < DataSender::Sender::SourceRegistry::Count(); i++) {
                    auto source = DataSender::Sender::SourceRegistry::Get(i);
                    if (source is null) continue;

                    bool enabled = DataSender::Sender::SourceRegistry::IsEnabled(source.id);
                    enabled = UI::Checkbox(source.label + " source##" + source.id, enabled);
                    DataSender::Sender::SourceRegistry::SetEnabled(source.id, enabled);
                    int interval = int(DataSender::Sender::SourceRegistry::IntervalMs(source.id));
                    UI::SetNextItemWidth(180.0f);
                    interval = UI::SliderInt(source.label + " interval (ms)##" + source.id, interval, 1, 1000);
                    DataSender::Sender::SourceRegistry::SetIntervalMs(source.id, uint(interval));
                }
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
