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
        }
    }
}
