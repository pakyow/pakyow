RSpec.describe "response headers for assets" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.assets.source_maps = false
    end
  end

  it "sets content-type" do
    expect(call("/assets/default.css")[1]["content-type"]).to eq("text/css")
  end

  context "asset is a pack" do
    it "sets content-type" do
      expect(call("/assets/packs/versioned.js")[1]["content-type"]).to eq("application/javascript")
    end
  end

  context "asset is a public file" do
    it "sets content-type" do
      expect(call("/robots.txt")[1]["content-type"]).to eq("text/plain")
    end
  end
end
