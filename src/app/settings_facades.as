namespace DataSender {
    namespace App {
        void RenderGeneralSettingsUI() {
            bool open = UI::BeginChild("##data-sender-settings-general", vec2(0, 0), false);
            if (open) {
                S_ShowRenderMenu = UI::Checkbox("Show render menu item", S_ShowRenderMenu);
                UI::Separator();
                DataSender::Sender::Service::S_AutoStart = UI::Checkbox(
                    "Start service on plugin load",
                    DataSender::Sender::Service::S_AutoStart
                );
                UI::Text("Current state: " + ServiceStateText());
                UI::Text("Runtime: " + ServiceDetailText());
                UI::Text("Updates: " + tostring(DataSender::Sender::Service::UpdateCount()));
                if (DataSender::Sender::Service::UpdateErrors() > 0) {
                    UI::Text("Update errors: " + ErrorText(tostring(DataSender::Sender::Service::UpdateErrors())));
                }
                RenderServiceControlButtons("settings-general");
            }
            UI::EndChild();
        }

        void RenderTcpServerSettingsUI() {
            bool open = UI::BeginChild("##data-sender-settings-tcp", vec2(0, 0), false);
            if (open) {
                UI::Text("State: " + TcpStateText());
                UI::Text("Address: " + DataSender::Server::Tcp::AddressText());
                UI::Text("Clients: " + tostring(DataSender::Server::Tcp::ClientCount()) + " / " + tostring(DataSender::Server::Tcp::MaxClients()));
                UI::Text("Messages sent: " + tostring(DataSender::Server::Tcp::TotalMessagesSent()));
                UI::Text("Telemetry coalesced: " + tostring(DataSender::Server::Tcp::TotalTelemetryDropped()));
                UI::Text("Accepted: " + tostring(DataSender::Server::Tcp::TotalAccepted()) + " | Rejected: " + tostring(DataSender::Server::Tcp::TotalRejected()) + " | Disconnected: " + tostring(DataSender::Server::Tcp::TotalDisconnected()));
                if (DataSender::Server::Tcp::UpdateErrors() > 0) {
                    UI::Text("TCP errors: " + ErrorText(tostring(DataSender::Server::Tcp::UpdateErrors())));
                }
                if (UI::Button("Copy address##settings-tcp-copy-address")) {
                    IO::SetClipboard(DataSender::Server::Tcp::AddressText());
                }
                RenderTcpError();
                UI::Separator();
                DataSender::Server::Tcp::S_Enabled = UI::Checkbox(
                    "Enable TCP server",
                    DataSender::Server::Tcp::S_Enabled
                );
                DataSender::Server::Tcp::S_AllowControlCommands = UI::Checkbox(
                    "Allow external control commands",
                    DataSender::Server::Tcp::S_AllowControlCommands
                );
                bool hostChanged = false;
                UI::SetNextItemWidth(220.0f);
                string host = UI::InputText(
                    "Host",
                    DataSender::Server::Tcp::S_Host,
                    hostChanged,
                    UI::InputTextFlags::CharsNoBlank
                );
                if (hostChanged) {
                    DataSender::Server::Tcp::S_Host = host.Trim().Length > 0 ? host.Trim() : "127.0.0.1";
                }

                int tcpPort = DataSender::Server::Tcp::S_Port;
                UI::SetNextItemWidth(180.0f);
                tcpPort = UI::InputInt("TCP port", tcpPort);
                DataSender::Server::Tcp::S_Port = Math::Clamp(tcpPort, 1, 65535);
                int tcpBroadcastInterval = int(DataSender::Server::Tcp::S_BroadcastIntervalMs);
                UI::SetNextItemWidth(180.0f);
                tcpBroadcastInterval = UI::SliderInt("TCP broadcast interval (ms)", tcpBroadcastInterval, 0, 1000);
                DataSender::Server::Tcp::S_BroadcastIntervalMs = uint(Math::Clamp(tcpBroadcastInterval, 0, 1000));
                UI::TextDisabled("0 ms broadcasts every service update.");
                int maxTelemetryPerSecond = DataSender::Server::Tcp::S_MaxTelemetryMessagesPerSecond;
                UI::SetNextItemWidth(180.0f);
                maxTelemetryPerSecond = UI::SliderInt("TCP max telemetry msgs/s", maxTelemetryPerSecond, 0, 2000);
                DataSender::Server::Tcp::S_MaxTelemetryMessagesPerSecond = Math::Clamp(maxTelemetryPerSecond, 0, 2000);
                UI::TextDisabled("0 disables telemetry rate limiting.");

                int tcpMaxClients = DataSender::Server::Tcp::S_MaxClients;
                UI::SetNextItemWidth(180.0f);
                tcpMaxClients = UI::SliderInt("TCP max clients", tcpMaxClients, 1, 64);
                DataSender::Server::Tcp::S_MaxClients = tcpMaxClients;

                UI::Separator();
                RenderTcpClientsTable("settings-tcp");
            }
            UI::EndChild();
        }

        void RenderSourcesSettingsUI() {
            bool open = UI::BeginChild("##data-sender-settings-sources", vec2(0, 0), false);
            if (open) {
                UI::Text("Enabled: " + tostring(EnabledSourceCount()) + " / " + tostring(DataSender::Sender::SourceRegistry::Count()));
                UI::Text("Samples: " + tostring(DataSender::Sender::SourceRegistry::TotalSamples()));
                if (UI::Button("Enable all##settings-sources-enable-all")) {
                    SetAllSourcesEnabled(true);
                }
                UI::SameLine();
                if (UI::Button("Disable all##settings-sources-disable-all")) {
                    SetAllSourcesEnabled(false);
                }
                UI::Separator();
                RenderSourceSettingsTable("settings");
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

        void SetAllSourcesEnabled(bool enabled) {
            for (uint i = 0; i < DataSender::Sender::SourceRegistry::Count(); i++) {
                auto source = DataSender::Sender::SourceRegistry::Get(i);
                if (source is null) continue;
                DataSender::Sender::SourceRegistry::SetEnabled(source.id, enabled);
            }
        }

        void RenderSourceSettingsTable(const string &in idPrefix) {
            if (!UI::BeginTable("##data-sender-source-settings-table-" + idPrefix, 6, StandardTableFlags())) return;

            UI::TableSetupColumn("Enabled", UI::TableColumnFlags::WidthFixed, 78.0f);
            UI::TableSetupColumn("Source");
            UI::TableSetupColumn("State", UI::TableColumnFlags::WidthFixed, 78.0f);
            UI::TableSetupColumn("Interval", UI::TableColumnFlags::WidthFixed, 128.0f);
            UI::TableSetupColumn("Samples", UI::TableColumnFlags::WidthFixed, 84.0f);
            UI::TableSetupColumn("Last sample", UI::TableColumnFlags::WidthFixed, 110.0f);
            UI::TableHeadersRow();

            for (uint i = 0; i < DataSender::Sender::SourceRegistry::Count(); i++) {
                auto source = DataSender::Sender::SourceRegistry::Get(i);
                if (source is null) continue;

                UI::TableNextRow();
                UI::TableNextColumn();
                bool enabled = DataSender::Sender::SourceRegistry::IsEnabled(source.id);
                bool newEnabled = UI::Checkbox("##" + idPrefix + "-enable-" + source.id, enabled);
                if (newEnabled != enabled) {
                    DataSender::Sender::SourceRegistry::SetEnabled(source.id, newEnabled);
                }
                UI::TableNextColumn();
                UI::Text(source.label);
                UI::TableNextColumn();
                UI::Text(SourceStateText(source.enabled, source.hasData));
                UI::TableNextColumn();
                int interval = int(DataSender::Sender::SourceRegistry::IntervalMs(source.id));
                UI::PushItemWidth(112.0f);
                interval = UI::InputInt("##" + idPrefix + "-interval-" + source.id, interval);
                UI::PopItemWidth();
                DataSender::Sender::SourceRegistry::SetIntervalMs(source.id, uint(Math::Clamp(interval, 1, 1000)));
                UI::TableNextColumn();
                UI::Text(tostring(source.samples));
                UI::TableNextColumn();
                UI::Text(AgeText(source.lastSampleAt));
            }
            UI::EndTable();
        }

        void RenderTcpClientsTable(const string &in idPrefix) {
            uint clients = DataSender::Server::Tcp::ClientCount();
            if (clients == 0) {
                UI::TextDisabled("No TCP clients connected.");
                return;
            }

            if (!UI::BeginTable("##data-sender-clients-" + idPrefix, 7, StandardTableFlags())) return;

            UI::TableSetupColumn("#", UI::TableColumnFlags::WidthFixed, 36.0f);
            UI::TableSetupColumn("Remote");
            UI::TableSetupColumn("Connected", UI::TableColumnFlags::WidthFixed, 110.0f);
            UI::TableSetupColumn("Messages", UI::TableColumnFlags::WidthFixed, 84.0f);
            UI::TableSetupColumn("Coalesced", UI::TableColumnFlags::WidthFixed, 86.0f);
            UI::TableSetupColumn("Subscriptions");
            UI::TableSetupColumn("Action", UI::TableColumnFlags::WidthFixed, 82.0f);
            UI::TableHeadersRow();

            for (uint i = 0; i < clients; i++) {
                auto client = DataSender::Server::Tcp::GetClient(i);
                if (client is null) continue;

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(tostring(i + 1));
                UI::TableNextColumn();
                UI::Text(client.RemoteIP());
                UI::TableNextColumn();
                UI::Text(AgeText(client.connectedAt));
                UI::TableNextColumn();
                UI::Text(tostring(client.messagesSent));
                UI::TableNextColumn();
                UI::Text(tostring(client.telemetryDropped));
                UI::TableNextColumn();
                UI::Text(client.SubscriptionText());
                UI::TableNextColumn();
                if (UI::Button("Drop##" + idPrefix + "-drop-client-" + tostring(i))) {
                    DataSender::Server::Tcp::DisconnectClient(i);
                    break;
                }
            }
            UI::EndTable();
        }
    }
}
