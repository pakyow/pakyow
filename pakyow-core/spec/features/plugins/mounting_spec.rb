require "pakyow/plugin"

RSpec.describe "mounting plugins" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      action :test
      def test(connection)
        connection.halt
      end
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/foo"
    end
  end

  it "exposes plugin-defined endpoints at the mount path" do
    expect(call("/foo/test-plugin")[0]).to eq(200)
  end

  context "plugin is mounted twice" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/foo"
        plug :testable, at: "/bar", as: :bar
      end
    end

    it "exposes each plugin-defined endpoint at the mount path" do
      expect(call("/foo/test-plugin")[0]).to eq(200)
      expect(call("/bar/test-plugin")[0]).to eq(200)
    end
  end
end
