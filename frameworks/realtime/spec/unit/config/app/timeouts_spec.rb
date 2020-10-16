RSpec.describe "realtime config", "timeouts" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.realtime.timeouts
  end

  describe "initial" do
    it "has a default value" do
      expect(config.initial).to eq(60)
    end
  end

  describe "disconnect" do
    it "has a default value" do
      expect(config.disconnect).to eq(24 * 60 * 60)
    end
  end
end
