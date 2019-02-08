RSpec.describe "environment realtime config" do
  before do
    Pakyow.setup
  end

  let :config do
    Pakyow.config.realtime
  end

  describe "server" do
    it "has a default value" do
      expect(config.server).to be(true)
    end
  end

  describe "adapter" do
    it "has a default value" do
      expect(config.adapter).to eq(:memory)
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default production value" do
        expect(config.adapter).to eq(:redis)
      end
    end
  end

  describe "adapter_settings" do
    it "has a default value" do
      expect(config.adapter_settings).to eq({})
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "has a default production value" do
        expect(config.adapter_settings).to eq(Pakyow.config.redis.to_h)
      end
    end
  end
end
