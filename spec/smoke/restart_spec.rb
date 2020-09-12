require "smoke_helper"

RSpec.describe "restarting a project", :repeatable, smoke: true do
  before do
    boot
  end

  context "page is added" do
    it "restarts" do
      # Give the filewatcher time to start.
      #
      sleep 5

      project_path.join("frontend/pages/index.html").open("w+") do |file|
        file.write <<~SOURCE
          hello web
        SOURCE
      end

      # Give the watcher time to notice the change.
      #
      sleep 0.5

      response = http.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("hello web")
    end
  end
end
