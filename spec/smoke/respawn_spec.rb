require "smoke_helper"

RSpec.describe "respawning a project", smoke: true do
  before do
    # Add the markdown page.
    #
    File.open(project_path.join("frontend/pages/index.md"), "w+") do |file|
      file.write <<~SOURCE
        **hello web**
      SOURCE
    end

    # Disable external asset fetching.
    # TODO: Remove this once we no longer restart when externals are fetched.
    #
    File.open(project_path.join("config/application.rb"), "w+") do |file|
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

  context "gem is added" do
    it "respawns" do
      # We have to sleep here, or filewatcher doesn't get initialized in time.
      # TODO: See if this can go away once we own file watching.
      #
      sleep 1

      File.open(project_path.join("Gemfile"), "a") do |file|
        file.write("\ngem \"pakyow-markdown\"")
      end

      # Wait for the process to respawn.
      #
      sleep 10

      response = HTTP.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("<strong>hello web</strong>")
    end
  end
end
