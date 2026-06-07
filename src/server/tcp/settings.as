namespace DataSender {
    namespace Server {
        namespace Tcp {
            const int DEFAULT_PORT = 28765;
            const int LEGACY_DEFAULT_PORT = 8765;

            [Setting hidden name="Enable TCP server"]
            bool S_Enabled = true;
            [Setting hidden name="TCP host"]
            string S_Host = "127.0.0.1";
            [Setting hidden name="TCP port" min=1 max=65535]
            int S_Port = DEFAULT_PORT;
            [Setting hidden name="TCP broadcast interval" min=0 max=1000]
            uint S_BroadcastIntervalMs = 100;
            [Setting hidden name="TCP max clients" min=1 max=64]
            int S_MaxClients = 8;
            [Setting hidden name="Allow TCP control commands"]
            bool S_AllowControlCommands = true;
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
        }
    }
}
