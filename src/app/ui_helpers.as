namespace DataSender {
    namespace App {
        string ColorText(const string &in text, const vec3 &in color) {
            return Text::FormatOpenplanetColor(color) + text + "\\$z";
        }

        string GoodText(const string &in text) {
            return ColorText(text, vec3(0.0f, 1.0f, 0.0f));
        }

        string WarnText(const string &in text) {
            return ColorText(text, vec3(1.0f, 0.8f, 0.0f));
        }

        string ErrorText(const string &in text) {
            return ColorText(text, vec3(1.0f, 0.45f, 0.0f));
        }

        string MutedText(const string &in text) {
            return ColorText(text, vec3(0.55f, 0.55f, 0.55f));
        }

        string ServiceStateText() {
            return DataSender::Sender::Service::IsRunning() ? GoodText("Running") : MutedText("Stopped");
        }

        string TcpStateText() {
            if (!DataSender::Server::Tcp::S_Enabled) return MutedText("Disabled");
            return DataSender::Server::Tcp::IsRunning() ? GoodText("Listening") : WarnText("Stopped");
        }

        string SourceStateText(bool enabled, bool hasData) {
            if (!enabled) return MutedText("Disabled");
            if (!hasData) return WarnText("Waiting");
            return GoodText("Live");
        }

        string FormatDuration(uint64 ms) {
            if (ms < 1000) return tostring(ms) + " ms";
            return Time::Format(ms, false, true, ms >= 3600000, true);
        }

        string AgeText(uint64 at) {
            if (at == 0) return "never";

            uint64 now = Time::Now;
            if (now <= at) return "now";
            return FormatDuration(now - uint64(at)) + " ago";
        }

        string ElapsedText(uint64 since) {
            if (since == 0) return "0 ms";

            uint64 now = Time::Now;
            if (now <= since) return "0 ms";
            return FormatDuration(now - uint64(since));
        }

        string ServiceDetailText() {
            if (DataSender::Sender::Service::IsRunning()) {
                return "up " + ElapsedText(DataSender::Sender::Service::StartedAt());
            }

            uint64 stoppedAt = DataSender::Sender::Service::StoppedAt();
            if (stoppedAt == 0) return "not started";
            return "stopped " + AgeText(stoppedAt);
        }

        int StandardTableFlags() {
            return UI::TableFlags::RowBg
                | UI::TableFlags::BordersInnerH
                | UI::TableFlags::SizingStretchProp;
        }

        uint EnabledSourceCount() {
            uint enabled = 0;
            for (uint i = 0; i < DataSender::Sender::SourceRegistry::Count(); i++) {
                auto source = DataSender::Sender::SourceRegistry::Get(i);
                if (source !is null && source.enabled) enabled++;
            }
            return enabled;
        }

        void RenderServiceControlButtons(const string &in idPrefix) {
            if (DataSender::Sender::Service::IsRunning()) {
                if (UI::Button("Stop##" + idPrefix + "-service-stop")) {
                    DataSender::Sender::Service::Stop();
                }
                UI::SameLine();
                if (UI::Button("Restart##" + idPrefix + "-service-restart")) {
                    DataSender::Sender::Service::Stop();
                    DataSender::Sender::Service::Start();
                }
            } else {
                if (UI::Button("Start##" + idPrefix + "-service-start")) {
                    DataSender::Sender::Service::Start();
                }
            }
        }

        void RenderTcpError() {
            string lastError = DataSender::Server::Tcp::LastError();
            if (lastError.Length == 0) return;
            UI::Text(ErrorText(lastError));
        }
    }
}
