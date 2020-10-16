RSpec.describe "assets config", "sass" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.sass
  end

  describe "cache" do
    it "has a default value" do
      expect(config.cache).to eq(false)
    end
  end

  describe "omit_source_map_url" do
    it "has a default value" do
      expect(config.omit_source_map_url).to eq(true)
    end
  end

  describe "source_map_contents" do
    it "has a default value" do
      expect(config.source_map_contents).to eq(true)
    end
  end

  describe "load_paths" do
    it "has a default value" do
      expect(config.load_paths).to eq([app.config.assets.path])
    end

    it "is dependent on assets path" do
      app.config.assets.path = "foo"
      expect(config.load_paths).to eq([app.config.assets.path])
    end
  end

  describe "style" do
    context "minify is true" do
      before do
        app.config.assets.minify = true
      end

      it "has a default value" do
        expect(config.style).to eq(:compressed)
      end
    end

    context "minify is false" do
      before do
        app.config.assets.minify = false
      end

      it "has a default value" do
        expect(config.style).to eq(:nested)
      end
    end
  end
end
