RSpec.describe "assets config" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets
  end

  describe "extensions" do
    it "includes an extension for each type" do
      expect(config.extensions).to eq(config.types.values.flatten)
    end
  end

  describe "public" do
    it "has a default value" do
      expect(config.public).to be(true)
    end
  end

  describe "process" do
    it "has a default value" do
      expect(config.process).to be(true)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is true" do
        expect(config.process).to be(false)
      end
    end
  end

  describe "cache" do
    it "has a default value" do
      expect(config.cache).to be(false)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is true" do
        expect(config.cache).to be(true)
      end
    end
  end

  describe "minify" do
    it "has a default value" do
      expect(config.minify).to be(false)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is true" do
        expect(config.minify).to be(true)
      end
    end
  end

  describe "fingerprint" do
    it "has a default value" do
      expect(config.fingerprint).to be(false)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is true" do
        expect(config.fingerprint).to be(true)
      end
    end
  end

  describe "autoloaded_packs" do
    it "has a default value" do
      expect(config.autoloaded_packs).to eq([:pakyow])
    end
  end

  describe "prefix" do
    it "has a default value" do
      expect(config.prefix).to eq("/assets")
    end
  end

  describe "public_path" do
    it "has a default value" do
      expect(config.public_path).to eq("./public")
    end

    it "is dependent on config.root" do
      app.config.root = "ROOT"
      expect(config.public_path).to eq("ROOT/public")
    end
  end

  describe "frontend_assets_path" do
    it "has a default value" do
      expect(config.frontend_assets_path).to eq("./frontend/assets")
    end

    it "is dependent on config.presenter.path" do
      app.config.presenter.path = "PRESENTER"
      expect(config.frontend_assets_path).to eq("PRESENTER/assets")
    end
  end

  describe "frontend_asset_packs_path" do
    it "has a default value" do
      expect(config.frontend_asset_packs_path).to eq("./frontend/assets/packs")
    end

    it "is dependent on config.assets.frontend_assets_path" do
      app.config.assets.frontend_assets_path = "FRONTEND_ASSETS_PATH"
      expect(config.frontend_asset_packs_path).to eq("FRONTEND_ASSETS_PATH/packs")
    end
  end

  describe "compilation_path" do
    it "has a default value" do
      expect(config.compilation_path).to eq("./public")
    end

    it "is dependent on config.assets.public_path" do
      app.config.assets.public_path = "PUBLIC_PATH"
      expect(config.public_path).to eq("PUBLIC_PATH")
    end
  end

  describe "silent" do
    it "has a default value" do
      expect(config.silent).to eq(true)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is false" do
        expect(config.silent).to be(false)
      end
    end
  end
end
