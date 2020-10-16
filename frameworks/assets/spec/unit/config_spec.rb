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

  describe "prefix" do
    it "has a default value" do
      expect(config.prefix).to eq("/assets")
    end
  end

  describe "public_path" do
    it "has a default value" do
      expect(config.public_path).to eq(File.join(Pakyow.config.root, "public"))
    end

    it "is dependent on config.root" do
      app.config.root = "ROOT"
      expect(config.public_path).to eq("ROOT/public")
    end
  end

  describe "path" do
    it "has a default value" do
      expect(config.path).to eq(File.join(Pakyow.config.root, "frontend/assets"))
    end

    it "is dependent on config.presenter.path" do
      app.config.presenter.path = "PRESENTER"
      expect(config.path).to eq("PRESENTER/assets")
    end
  end

  describe "paths" do
    it "has a default value" do
      expect(config.paths).to eq([File.join(Pakyow.config.root, "frontend/assets")])
    end

    it "is dependent on config.assets.path" do
      app.config.assets.path = "FRONTEND_ASSETS_PATH"
      expect(config.paths).to eq(["FRONTEND_ASSETS_PATH"])
    end
  end

  describe "compile_path" do
    it "has a default value" do
      expect(config.compile_path).to eq(File.join(Pakyow.config.root, "public"))
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

  describe "source_maps" do
    it "has a default value" do
      expect(config.source_maps).to eq(true)
    end

    context "in production" do
      before do
        app.configure!(:production)
      end

      it "is true" do
        expect(config.source_maps).to be(true)
      end
    end
  end

  describe "version" do
    before do
      expect(Pakyow::Support::PathVersion).to receive(:build).with(config.path, config.public_path).and_return("digest")
    end

    it "has a default value" do
      expect(config.version).to eq("digest")
    end
  end

  describe "common_assets_path" do
    it "has a default value" do
      expect(Pakyow.config.common_assets_path).to eq(File.join(Pakyow.config.common_frontend_path, "assets"))
    end
  end

  describe "common_asset_packs_path" do
    it "has a default value" do
      expect(Pakyow.config.common_asset_packs_path).to eq(File.join(Pakyow.config.common_frontend_path, "assets/packs"))
    end
  end
end
