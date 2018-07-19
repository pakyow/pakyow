RSpec.describe "assets config", "externals" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.externals
  end

  describe "fetch" do
    it "has a default value" do
      expect(config.fetch).to be(true)
    end

    context "in test" do
      before do
        app.configure!(:test)
      end

      it "is false" do
        expect(config.fetch).to be(false)
      end
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is false" do
        expect(config.fetch).to be(false)
      end
    end
  end

  describe "pakyow" do
    it "has a default value" do
      expect(config.pakyow).to be(true)
    end
  end

  describe "provider" do
    it "has a default value" do
      expect(config.provider).to eq("https://unpkg.com/")
    end
  end

  describe "scripts" do
    it "has a default value" do
      expect(config.scripts).to eq([])
    end
  end

  describe "path" do
    it "has a default value" do
      expect(config.path).to eq("./frontend/assets/packs/vendor")
    end

    it "is dependent on config.assets.packs.path" do
      app.config.assets.packs.path = "FRONTEND_ASSET_PACKS_PATH"
      expect(config.path).to eq("FRONTEND_ASSET_PACKS_PATH/vendor")
    end
  end
end
