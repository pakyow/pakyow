require "smoke_helper"

RSpec.describe "serving assets", smoke: true do
  before do
    setup; boot
  end

  def setup
    stylesheet_path = assets_path.join("styles/default.css")
    FileUtils.mkdir_p(stylesheet_path.dirname)

    File.open(stylesheet_path, "w+") do |file|
      file.write <<~SOURCE
        body {
          background: purple;
        }
      SOURCE
    end
  end

  let(:assets_path) {
    project_path.join("frontend/assets")
  }

  it "responds to a request" do
    response = HTTP.get("http://localhost:#{port}/assets/styles/default.css")

    expect(response.status).to eq(200)
    expect(response.body.to_s).to include("background: purple")
  end

  context "non-standard assets path" do
    def setup
      super

      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test do
            configure do
              config.assets.path = File.join(config.presenter.path, "custom-assets")
            end
          end
        SOURCE
      end
    end

    let(:assets_path) {
      project_path.join("frontend/custom-assets")
    }

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}/assets/styles/default.css")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("background: purple")
    end
  end
end
