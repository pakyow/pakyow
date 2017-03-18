RSpec.shared_context "testable app" do
  let :app do
    Pakyow::App
  end
  
  let :app_runtime_block do
    -> {}
  end

  before do
    Pakyow.config.server.default = :mock
    define
    run
  end

  after do
    Pakyow.reset
    app.reset
  end
end
