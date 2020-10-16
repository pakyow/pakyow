require "pakyow/plugin"

RSpec.describe "building a path to a plugin endpoint" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/foo"
    end
  end

  it "builds the path to the endpoint using `path`" do
    expect(
      Pakyow.app(:test).plugs.testable.endpoints.path(:root)
    ).to eq("/foo/test-plugin")
  end

  it "builds the path to the endpoint using `path_to`" do
    expect(
      Pakyow.app(:test).plugs.testable.endpoints.path_to(:root, :default)
    ).to eq("/foo/test-plugin")
  end

  context "endpoint is not a GET endpoint" do
    it "builds the path to the plugin endpoint" do
      expect(
        Pakyow.app(:test).plugs.testable.endpoints.path(:root_non_get)
      ).to eq("/foo/test-plugin/non_get")
    end

    it "recognizes the correct method" do
      expect(Pakyow.app(:test).plugs.testable.endpoints.find(name: :root_non_get).method).to eq(:post)
    end
  end

  context "endpoint name conflicts between the app and plugin" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/foo"

        controller :root, "/" do
          default
        end
      end
    end

    it "builds the path to the app endpoint" do
      expect(
        Pakyow.app(:test).endpoints.path(:root)
      ).to eq("/")
    end

    it "builds the path to the plugin endpoint" do
      expect(
        Pakyow.app(:test).plugs.testable.endpoints.path(:root)
      ).to eq("/foo/test-plugin")
    end
  end

  describe "accessing plugin endpoints through the app" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/foo"
        plug :testable, at: "/bar", as: :bar
      end
    end

    it "builds the path to an endpoint in the default instance" do
      expect(
        Pakyow.app(:test).endpoints.path(:testable_root)
      ).to eq("/foo/test-plugin")
    end

    it "builds the path to an endpoint in the named instance" do
      expect(
        Pakyow.app(:test).endpoints.path(:testable_bar_root)
      ).to eq("/bar/test-plugin")
    end
  end

  describe "accessing plugin endpoints from within a plugin controller" do
    it "builds the path" do
      expect(call("/foo/test-plugin/endpoint/root")[2]).to eq("/foo/test-plugin")
    end
  end

  describe "accessing app endpoints from within a plugin controller" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/foo"

        controller :root, "/" do
          default
        end
      end
    end

    it "builds the path" do
      expect(call("/foo/test-plugin/app_endpoint/root")[2]).to eq("/")
    end
  end
end
