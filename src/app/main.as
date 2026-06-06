namespace DataSender {
    namespace App {
        void Main() {
            logging::Initialise();
            log(
                "Loaded " + DataSender::PluginMeta.Name + " v" + DataSender::PluginMeta.Version,
                LogLevel::Debug,
                6,
                "DataSender::App::Main"
            );
        }

        bool ShouldRenderWindow() {
            if (!S_WindowOpen) return false;
            if (S_HideWithGame && !UI::IsGameUIVisible()) return false;
            if (S_HideWithOP && !UI::IsOverlayShown()) return false;
            return true;
        }

        void RenderInterface() {
            if (!ShouldRenderWindow()) return;

            if (UI::Begin(MenuTitle() + "###main-" + DataSender::PluginMeta.ID, S_WindowOpen, UI::WindowFlags::None)) {
                RenderWindow();
            }
            UI::End();
        }

        void RenderMenu() {
            if (UI::MenuItem(MenuTitle(), "", S_WindowOpen)) {
                S_WindowOpen = !S_WindowOpen;
            }
        }

        void RenderWindow() {
            UI::Text(DataSender::PluginMeta.Name + " " + DataSender::PluginMeta.Version);
            UI::Separator();
            UI::Text("Service: " + DataSender::Sender::Service::StatusText());
            UI::SameLine();
            if (DataSender::Sender::Service::IsRunning()) {
                if (UI::Button("Stop##data-sender-service")) {
                    DataSender::Sender::Service::Stop();
                }
            } else {
                if (UI::Button("Start##data-sender-service")) {
                    DataSender::Sender::Service::Start();
                }
            }
            UI::Text("Clients: " + tostring(DataSender::Sender::Service::ConnectedClientCount()));
            UI::Text("TCP: " + DataSender::Server::Tcp::StatusText() + " " + DataSender::Server::Tcp::AddressText());
            UI::Text("TCP messages sent: " + tostring(DataSender::Server::Tcp::TotalMessagesSent()));
            if (DataSender::Server::Tcp::LastError().Length > 0) {
                UI::Text("\\$f80" + DataSender::Server::Tcp::LastError());
            }
            UI::Text("Source samples: " + tostring(DataSender::Sender::SourceRegistry::TotalSamples()));

            for (uint i = 0; i < DataSender::Sender::SourceRegistry::Count(); i++) {
                auto source = DataSender::Sender::SourceRegistry::Get(i);
                if (source is null) continue;

                string state = source.enabled ? "enabled" : "disabled";
                UI::Text(source.label + ": " + state + ", " + tostring(source.samples) + " samples");
            }
        }
    }
}
