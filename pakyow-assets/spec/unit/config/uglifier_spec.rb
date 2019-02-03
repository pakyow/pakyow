RSpec.describe "assets config", "uglifier" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.uglifier
  end

  describe "source_map" do
    let :config do
      super().source_map
    end

    describe "sources_content" do
      it "has a default value" do
        expect(config.sources_content).to eq(true)
      end
    end
  end
end
