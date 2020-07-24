require "smoke_helper"

RSpec.describe "respawning a project", smoke: true do
  context "gem is added" do
    before do
      # Add the markdown page.
      #
      File.open(project_path.join("frontend/pages/index.md"), "w+") do |file|
        file.write <<~SOURCE
          **hello web**
        SOURCE
      end

      boot
    end

    it "respawns" do
      # Give the filewatcher time to start.
      #
      sleep 5

      File.open(project_path.join("Gemfile"), "a") do |file|
        file.write("\ngem \"pakyow-markdown\"")
      end

      # Give bundler time to install.
      #
      sleep 10

      response = http.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("<strong>hello web</strong>")
    end
  end

  context "bundle error is introduced" do
    before do
      # Add the markdown page.
      #
      File.open(project_path.join("frontend/pages/index.html"), "w+") do |file|
        file.write <<~SOURCE
          hello web
        SOURCE
      end

      boot
    end

    it "does not respawn, but continues running" do
      # Give the filewatcher time to start.
      #
      sleep 5

      File.open(project_path.join("Gemfile"), "a") do |file|
        file.write("\ngem \"thisisagemthatdoesnotexist\"")
      end

      # Give bundler time to install.
      #
      sleep 10

      response = http.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("hello web")
    end
  end
end
