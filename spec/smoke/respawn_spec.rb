require "smoke_helper"

RSpec.describe "respawning a project", :repeatable, smoke: true do
  context "gem is added" do
    before do
      # Add the markdown page.
      #
      # File.open(project_path.join("frontend/pages/index.md"), "w+") do |file|
      #   file.write <<~SOURCE
      #     **hello web**
      #   SOURCE
      # end

      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test, only: %i[routing data] do
            controller "/" do
              default do
                send defined?(Dry::Configurable).to_s
              end
            end
          end
        SOURCE
      end

      boot
    end

    it "respawns" do
      # Give the filewatcher time to start.
      #
      sleep 5

      File.open(project_path.join("Gemfile"), "a") do |file|
        file.write("\ngem \"dry-configurable\"")
      end

      # Give bundler time to install.
      #
      sleep 10

      response = http.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("constant")
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
