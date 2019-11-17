require "smoke_helper"

RSpec.describe "starting up a newly generated project", smoke: true do
  before do
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

    boot do
      # TODO: Enable this once externals are fetched in the background.
      #
      # expect(@boot_time).to be < 10
    end
  end

  context "development environment" do
    let :environment do
      :development
    end

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}")

      # It'll 404 because of the default view missing message. This is fine.
      #
      expect(response.status).to eq(404)
    end
  end

  context "production environment" do
    let :environment do
      :production
    end

    let :envars do
      {
        "SECRET" => "sekret",
        "DATABASE_URL" => "sqlite://database/production.db"
      }
    end

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}")

      # It'll 404 because of the default view missing message. This is fine.
      #
      expect(response.status).to eq(404)
    end
  end
end
