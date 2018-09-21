require "pakyow/plugin"

RSpec.describe "accessing plugin config" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      setting :foo, :bar
      setting :baz, :qux
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "testable app"

  let :app_definition do
    Proc.new {
      plug :testable, at: "/"
      plug :testable, at: "/foo", as: :foo

      setting :app_setting, :app_value
      setting :baz, :app_qux
    }
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

  it "copies settings and values from the app" do
    expect(
      Pakyow.app(:test).plugs.testable.config.app_setting
    ).to eq(:app_value)
  end

  context "plugin defines the same setting as the app" do
    it "gives precedence to the plugin value" do
      expect(
        Pakyow.app(:test).plugs.testable.config.baz
      ).to eq(:qux)
    end
  end

  describe "app config" do
    it "does not expose plugin config" do
      expect {
        Pakyow.app(:test).config.foo
      }.to raise_error(RuntimeError)
    end
  end
end
