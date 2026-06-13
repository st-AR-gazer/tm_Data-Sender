namespace DataSender {
    namespace Server {
        namespace Tcp {
            const int DEFAULT_PORT = 28765;
            const int LEGACY_DEFAULT_PORT = 8765;
            const uint START_RETRY_MS = 3000;
            const uint ACCEPTS_PER_UPDATE = 8;
            const uint MAX_COMMAND_ERRORS = 16;
            const uint MAX_SOURCE_IDS_PER_COMMAND = 32;
            const uint MAX_FIELD_PATHS_PER_SOURCE = 128;

            [Setting hidden name="Enable TCP server"]
            bool S_Enabled = true;
            [Setting hidden name="TCP host"]
            string S_Host = "127.0.0.1";
            [Setting hidden name="TCP port" min=1 max=65535]
            int S_Port = DEFAULT_PORT;
            [Setting hidden name="TCP broadcast interval" min=0 max=1000]
            uint S_BroadcastIntervalMs = 100;
            [Setting hidden name="TCP max telemetry messages per second" min=0 max=2000]
            int S_MaxTelemetryMessagesPerSecond = 120;
            [Setting hidden name="TCP max clients" min=1 max=64]
            int S_MaxClients = 8;
            [Setting hidden name="Allow TCP control commands"]
            bool S_AllowControlCommands = true;
            [Setting hidden name="TCP max command bytes" min=1024 max=65536]
            int S_MaxCommandBytes = 32768;
            [Setting hidden name="TCP max commands per update" min=1 max=64]
            int S_MaxCommandsPerUpdate = 16;
            [Setting hidden name="TCP unsubscribed client timeout" min=0 max=600000]
            int S_UnsubscribedClientTimeoutMs = 60000;
            [Setting hidden name="Migrated old default TCP port"]
            bool S_MigratedOldDefaultPort = false;

            string ConfiguredHost() {
                string host = S_Host.Trim();
                if (host.Length == 0) {
                    host = "127.0.0.1";
                    S_Host = host;
                }
                return host;
            }

            uint16 ConfiguredPort() {
                MigrateOldDefaultPort();
                S_Port = Math::Clamp(S_Port, 1, 65535);
                return uint16(S_Port);
            }

            void MigrateOldDefaultPort() {
                if (S_MigratedOldDefaultPort) return;
                if (S_Port == LEGACY_DEFAULT_PORT) {
                    S_Port = DEFAULT_PORT;
                }
                S_MigratedOldDefaultPort = true;
            }

            uint BroadcastIntervalMs() {
                return S_BroadcastIntervalMs > 1000 ? 1000 : S_BroadcastIntervalMs;
            }

            uint MaxClients() {
                S_MaxClients = Math::Clamp(S_MaxClients, 1, 64);
                return uint(S_MaxClients);
            }

            uint MaxTelemetryMessagesPerSecond() {
                S_MaxTelemetryMessagesPerSecond = Math::Clamp(S_MaxTelemetryMessagesPerSecond, 0, 2000);
                return uint(S_MaxTelemetryMessagesPerSecond);
            }

            uint MaxCommandBytes() {
                S_MaxCommandBytes = Math::Clamp(S_MaxCommandBytes, 1024, 65536);
                return uint(S_MaxCommandBytes);
            }

            uint MaxCommandsPerUpdate() {
                S_MaxCommandsPerUpdate = Math::Clamp(S_MaxCommandsPerUpdate, 1, 64);
                return uint(S_MaxCommandsPerUpdate);
            }

            uint UnsubscribedClientTimeoutMs() {
                S_UnsubscribedClientTimeoutMs = Math::Clamp(S_UnsubscribedClientTimeoutMs, 0, 600000);
                return uint(S_UnsubscribedClientTimeoutMs);
            }

            uint StartRetryMs() {
                return START_RETRY_MS;
            }

            uint AcceptsPerUpdate() {
                return ACCEPTS_PER_UPDATE;
            }

            uint MaxCommandErrors() {
                return MAX_COMMAND_ERRORS;
            }

            uint MaxSourceIdsPerCommand() {
                return MAX_SOURCE_IDS_PER_COMMAND;
            }

            uint MaxFieldPathsPerSource() {
                return MAX_FIELD_PATHS_PER_SOURCE;
            }
        }
    }
}
