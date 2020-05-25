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

    boot
  end

  context "gem is added" do
    it "respawns" do
      File.open(project_path.join("Gemfile"), "a") do |file|
        file.write("\ngem \"pakyow-markdown\"")
      end

      # Give bundler time to install.
      #
      sleep 10

      response = HTTP.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to include("<strong>hello web</strong>")
    end
  end
end
