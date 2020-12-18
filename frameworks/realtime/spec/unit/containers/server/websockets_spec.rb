RSpec.describe "server.websockets service" do
  let(:service) {
    Pakyow.container(:server).service(:websockets)
  }

  let(:instance) {
    service.new(**options)
  }

  let(:options) {
    {}
  }

  let(:server) {
    instance_double(Pakyow::Realtime::Server)
  }

  before do
    allow(Pakyow::Realtime::Server).to receive(:run).and_return(server)
  end

  describe "#perform" do
    it "runs the realtime server" do
      expect(Pakyow::Realtime::Server).to receive(:run).with(
        Pakyow.config.realtime.adapter,
        Pakyow.config.realtime.adapter_settings.to_h,
        Pakyow.config.realtime.timeouts
      )

      instance.perform
    end
  end

  describe "#shutdown" do
    before do
      instance.perform
    end

    it "shuts down the realtime server" do
      expect(server).to receive(:shutdown)

      instance.shutdown
    end
  end
end
