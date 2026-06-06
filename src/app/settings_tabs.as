[SettingsTab name="General" icon="Cog" order=1]
void RenderDataSenderGeneralSettingsTab() {
    DataSender::App::RenderGeneralSettingsUI();
}

[SettingsTab name="TCP Server" icon="Server" order=2]
void RenderDataSenderTcpServerSettingsTab() {
    DataSender::App::RenderTcpServerSettingsUI();
}

[SettingsTab name="Sources" icon="Database" order=3]
void RenderDataSenderSourcesSettingsTab() {
    DataSender::App::RenderSourcesSettingsUI();
}

[SettingsTab name="Logging" icon="ListAlt" order=99]
void RenderDataSenderLoggingSettingsTab() {
    DataSender::App::RenderLoggingSettingsUI();
}
