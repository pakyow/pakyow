require "smoke_helper"

RSpec.describe "restarting a project", smoke: true do
  before do
    # Disable external asset fetching.
    # TODO: Remove this once we no longer restart when externals are fetched.
    #
    project_path.join("config/application.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test do
          configure do
            config.assets.externals.fetch = false
          end
        end
      SOURCE
    end

    boot
  end

  context "page is added" do
    it "restarts" do
      # We have to sleep here, or filewatcher doesn't get initialized in time.
      # TODO: See if this can go away once we own file watching.
      #
      sleep 1

      project_path.join("frontend/pages/index.html").open("w+") do |file|
        file.write <<~SOURCE
          hello web
        SOURCE
      end

      # wait for the process to restart
      #
      sleep 5

      response = HTTP.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("hello web")
    end
  end
end
