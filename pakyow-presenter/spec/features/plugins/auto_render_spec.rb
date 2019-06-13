require "pakyow/plugin"

RSpec.describe "auto rendering from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"

      configure do
        config.root = File.join(__dir__, "support/app")
      end
    end
  end

  context "view exists" do
    it "auto renders" do
      expect(call("/auto-render/plugin")[2]).to include("plugin auto render")
    end
  end

  context "view exists in the app but not the plugin" do
    it "auto renders from the app" do
      expect(call("/auto-render/app")[2]).to include("app auto render")
    end
  end
end
