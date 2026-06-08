namespace DataSender {
    namespace App {
        void Main() {
            logging::Initialise();
            log(
                "Loaded " + DataSender::PluginMeta.Name + " v" + DataSender::PluginMeta.Version,
                LogLevel::Debug,
                5,
                "DataSender::App::Main"
            );
        }

        void RenderMenu() {
            if (!S_ShowRenderMenu) return;

            bool running = DataSender::Sender::Service::IsRunning();
            string iconColor = running ? "\\$078" : "\\$888";
            string menuLabel = iconColor + Icons::Rss + Icons::Link + "\\$z " + DataSender::PluginMeta.Name;
            bool toggleClicked = UI::MenuItem(menuLabel, "", running);

            if (UI::IsItemClicked(UI::MouseButton::Right)) {
                Meta::OpenSettings(DataSender::PluginMeta);
                return;
            }

            if (toggleClicked) {
                if (running) {
                    DataSender::Sender::Service::Stop();
                } else {
                    DataSender::Sender::Service::Start();
                }
            }
        }
    }
}
