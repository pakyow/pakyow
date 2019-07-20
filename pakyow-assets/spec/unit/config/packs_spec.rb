RSpec.describe "assets config", "packs" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.packs
  end

  describe "autoload" do
    it "has a default value" do
      expect(config.autoload).to eq([:pakyow])
    end

    context "in development" do
      before do
        app.configure!(:development)
      end

      it "has a default value" do
        expect(config.autoload).to eq([:pakyow, :devtools])
      end
    end

    context "in prototype" do
      before do
        app.configure!(:prototype)
      end

      it "has a default value" do
        expect(config.autoload).to eq([:pakyow, :devtools])
      end
    end
  end

  describe "path" do
    it "has a default value" do
      expect(config.path).to eq(File.join(Pakyow.config.root, "frontend/assets/packs"))
    end

    it "is dependent on config.assets.path" do
      app.config.assets.path = "FRONTEND_ASSETS_PATH"
      expect(config.path).to eq("FRONTEND_ASSETS_PATH/packs")
    end
  end

  describe "paths" do
    it "has a default value" do
      expect(config.paths).to eq([File.join(Pakyow.config.root, "frontend/assets/packs"), File.join(Pakyow.config.root, "frontend/assets/packs/vendor")])
    end

    it "is dependent on config.assets.packs.path" do
      app.config.assets.packs.path = "FRONTEND_ASSET_PACKS_PATH"
      expect(config.paths).to eq(["FRONTEND_ASSET_PACKS_PATH", "FRONTEND_ASSET_PACKS_PATH/vendor"])
    end
  end
end
