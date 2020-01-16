require "pakyow/plugin"

RSpec.describe "accessing plugin config" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      setting :foo, :bar
      setting :baz, :qux
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"
      plug :testable, at: "/foo", as: :foo

      setting :app_setting, :app_value
      setting :baz, :app_qux

      configurable :app_group do
        setting :app_group_setting, true
      end
    end
  end

  it "exposes the plugin name" do
    expect(
      Pakyow.app(:test).plugs.testable.config.name
    ).to eq(:testable)

    expect(
      Pakyow.app(:test).plugs.testable(:foo).config.name
    ).to eq(:testable_foo)
  end

  it "exposes the plugin root" do
    expect(
      Pakyow.app(:test).plugs.testable.config.root
    ).to eq(File.expand_path("../support/plugin", __FILE__))
  end

  it "exposes the plugin src" do
    expect(
      Pakyow.app(:test).plugs.testable.config.src
    ).to eq(File.expand_path("../support/plugin/backend", __FILE__))
  end

  it "exposes plugin config" do
    expect(
      Pakyow.app(:test).plugs.testable.config.foo
    ).to eq(:bar)
  end

  context "plugin defines the same setting as the app" do
    it "gives precedence to the plugin value" do
      expect(
        Pakyow.app(:test).plugs.testable.config.baz
      ).to eq(:qux)
    end
  end

  context "plugin changes a config value it inherited from the app" do
    it "does not change the value from the perspective of the app"
  end

  describe "app config" do
    it "does not expose plugin config" do
      expect {
        Pakyow.app(:test).config.foo
      }.to raise_error(NoMethodError)
    end
  end
end
