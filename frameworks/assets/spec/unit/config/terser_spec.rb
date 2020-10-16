RSpec.describe "assets config", "terser" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.terser
  end

  describe "source_map" do
    describe "include_sources" do
      it "has a default value" do
        expect(config.source_map.include_sources).to eq(true)
      end
    end
  end
end
