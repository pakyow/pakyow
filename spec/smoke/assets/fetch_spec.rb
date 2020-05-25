require "smoke_helper"

RSpec.describe "fetching external assets on boot", smoke: true do
  before do
    project_path.join("config/application.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test do
          external_script :jquery, "<=3.3.1"
        end
      SOURCE
    end

    boot
  end

  it "fetches" do
    # Give the external assets fetcher time to run.
    #
    sleep 15

    expect(Dir.glob(project_path.join("frontend/assets/**/*"))).to include(
      project_path.join("frontend/assets/packs/vendor/jquery@3.3.1.js").to_s
    )
  end
end
