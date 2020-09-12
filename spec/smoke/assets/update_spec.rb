require "smoke_helper"

RSpec.describe "updating external assets", :repeatable, smoke: true do
  before do
    project_path.join("config/application.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test do
          external_script :d3, "=5.15.0"
          external_script :jquery, "=3.3.1"
        end
      SOURCE
    end

    FileUtils.rm_rf project_path.join("frontend/assets/packs/vendor")
  end

  it "updates a single asset" do
    cli_run "assets:update -a smoke_test d3"

    expect(Dir.glob(project_path.join("frontend/assets/**/*"))).to include(
      project_path.join("frontend/assets/packs/vendor/d3@5.15.0.js").to_s
    )
  end

  it "updates all assets" do
    cli_run "assets:update -a smoke_test"

    expect(Dir.glob(project_path.join("frontend/assets/**/*"))).to include(
      project_path.join("frontend/assets/packs/vendor/d3@5.15.0.js").to_s
    )

    expect(Dir.glob(project_path.join("frontend/assets/**/*"))).to include(
      project_path.join("frontend/assets/packs/vendor/jquery@3.3.1.js").to_s
    )
  end
end
