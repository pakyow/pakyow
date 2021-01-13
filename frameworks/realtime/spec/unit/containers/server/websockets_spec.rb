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
    instance_double(Pakyow::Realtime::Server, run: nil)
  }

  before do
    allow(Pakyow::Realtime::Server).to receive(:new).with(
      Pakyow.config.realtime.adapter,
      Pakyow.config.realtime.adapter_settings.to_h,
      Pakyow.config.realtime.timeouts
    ).and_return(server)
  end

  describe "#perform" do
    it "runs the realtime server" do
      expect(server).to receive(:run)

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
