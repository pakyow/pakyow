# TODO: Test that it responds to requests, even with non-standard path.
#   Do this also for presenter and assets (public, other assets).
#   Make sure to add new smoke tests to ci!

require "smoke_helper"

RSpec.describe "presenting views", :repeatable, smoke: true do
  before do
    setup; boot
  end

  def setup
    root_page_template_path = frontend_path.join("pages/index.html")
    FileUtils.mkdir_p(root_page_template_path.dirname)

    File.open(root_page_template_path, "w+") do |file|
      file.write <<~SOURCE
        presented
      SOURCE
    end
  end

  let(:frontend_path) {
    project_path.join("frontend")
  }

  it "responds to a request" do
    response = http.get("http://localhost:#{port}")

    expect(response.status).to eq(200)
    expect(response.body.to_s).to include("presented")
  end

  context "non-standard frontend path" do
    def setup
      FileUtils.mv(project_path.join("frontend"), project_path.join("custom-frontend"))

      super

      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test do
            configure do
              config.presenter.path = File.join(config.root, "custom-frontend")
            end
          end
        SOURCE
      end
    end

    let(:frontend_path) {
      project_path.join("custom-frontend")
    }

    it "responds to a request" do
      response = http.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("presented")
    end
  end
end
