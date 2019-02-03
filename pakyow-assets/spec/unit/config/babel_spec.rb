RSpec.describe "assets config", "babel" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.babel
  end

  describe "presets" do
    it "has a default value" do
      expect(config.presets).to eq(["es2015"])
    end
  end

  describe "source_maps" do
    it "has a default value" do
      expect(config.source_maps).to eq(true)
    end

    it "is dependent on config.assets.source_maps" do
      app.config.assets.source_maps = false
      expect(config.source_maps).to eq(false)
    end
  end
end
