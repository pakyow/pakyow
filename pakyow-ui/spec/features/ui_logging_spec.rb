RSpec.describe "ui logging" do
  include_context "app"

  it "registers a `log' handler" do
    expect(Pakyow.app(:test).class.__websocket_handlers["log"].count).to eq(1)
  end

  describe "handler" do
    let :payload do
      {}
    end

    let :socket do
      double
    end

    it "calls Pakyow::Application::Behavior::UI::Logging::log" do
      expect(Pakyow::Application::Behavior::UI::Logging).to receive(:log).with(payload, Test::Application)
      Pakyow.app(:test).class.__websocket_handlers["log"][0].call(payload, socket)
    end
  end
end
