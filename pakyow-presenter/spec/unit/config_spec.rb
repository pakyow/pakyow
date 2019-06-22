RSpec.describe "presenter config" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.presenter
  end

  describe "path" do
    it "has a default value" do
      expect(config.path).to eq(File.join(Pakyow.config.root, "frontend"))
    end

    it "is dependent on config.root" do
      app.config.root = "ROOT"
      expect(config.path).to eq("ROOT/frontend")
    end
  end

  describe "embed_authenticity_token" do
    it "has a default value" do
      expect(config.embed_authenticity_token).to eq(true)
    end
  end

  describe "version" do
    it "has a default value" do
      expect(config.version).to eq(nil)
    end
  end

  describe "features.streaming" do
    it "has a default value" do
      expect(config.features.streaming).to be(false)
    end
  end
end
