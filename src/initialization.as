void Main() {
    DataSender::App::Main();
}

void Update(float dt) {
    DataSender::Sender::Service::Update(dt);
}

void Render() {
    DataSender::Sender::Service::Render();
}

void RenderMenu() {
    DataSender::App::RenderMenu();
}

void OnDestroyed() {
    DataSender::Sender::Service::Shutdown();
}
