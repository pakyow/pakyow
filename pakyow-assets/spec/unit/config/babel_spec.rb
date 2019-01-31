RSpec.describe "assets config", "babel" do
  let :app do
    Pakyow.app(:test)
  end

  let :config do
    app.config.assets.babel
  end

  it "defines presets" do
    expect(config.presets).to eq(["es2015"])
  end
end
