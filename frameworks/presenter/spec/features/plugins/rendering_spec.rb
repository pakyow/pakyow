require "pakyow/plugin"

RSpec.describe "rendering an app view from the plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  context "plugin is namespaced" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/testable"

        configure do
          config.root = File.join(__dir__, "support/app")
        end
      end
    end

    it "renders the view" do
      response = call("/testable/test-plugin/render/app")
      expect(response[0]).to eq(200)
      expect(response[2]).to include("app only view")
    end
  end
end
