void Main() {
    DataSender::App::Main();
}

void Update(float dt) {
    DataSender::Sender::Service::Update(dt);
}

void RenderMenu() {
    DataSender::App::RenderMenu();
}

void OnDestroyed() {
    DataSender::Sender::Service::Shutdown();
}
