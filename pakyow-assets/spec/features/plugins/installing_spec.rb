require "pakyow/plugin"

RSpec.describe "installing assets into a view" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable

      configure do
        config.root = File.join(__dir__, "support/app")
      end
    end
  end

  it "includes the app's assets" do
    expect(call("/")[2]).to include("/assets/packs/layouts/default.css")
  end

  it "does not duplicate assets" do
    expect(call("/")[2].scan("/assets/packs/foo.js").count).to eq(1)
  end

  it "loads assets in the correct order" do
    expect(
      call("/")[2].scan(/src=\"\/assets\/packs\/([^\"]*)/).to_a.flatten
    ).to eq(["foo.js", "bar.js", "baz.js"])
  end
end
