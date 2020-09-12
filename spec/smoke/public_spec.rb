require "smoke_helper"

RSpec.describe "serving public files", :repeatable, smoke: true do
  before do
    setup; boot
  end

  def setup
    # intentionally empty
  end

  it "responds to a request" do
    response = http.get("http://localhost:#{port}/robots.txt")

    expect(response.status).to eq(200)
    expect(response.body.to_s).to include("Allow: /")
  end

  context "non-standard public path" do
    def setup
      super

      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test do
            configure do
              config.assets.public_path = File.join(config.root, "custom-public")
            end
          end
        SOURCE
      end

      FileUtils.mv(project_path.join("public"), project_path.join("custom-public"))
    end

    it "responds to a request" do
      response = http.get("http://localhost:#{port}/robots.txt")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("Allow: /")
    end
  end
end
