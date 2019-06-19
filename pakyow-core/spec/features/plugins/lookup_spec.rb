require "pakyow/plugin"

RSpec.describe "looking up plugin instances" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"
      plug :testable, at: "/foo", as: :foo
    end
  end

  it "looks up an unnamed plugin" do
    expect(Pakyow.app(:test).plugs.testable.class.name).to eq("Test::Testable::Default::Plug")
  end

  it "looks up an unnamed plugin as default" do
    expect(Pakyow.app(:test).plugs.testable(:default).class.name).to eq("Test::Testable::Default::Plug")
  end

  it "looks up a named plugin" do
    expect(Pakyow.app(:test).plugs.testable(:foo).class.name).to eq("Test::Testable::Foo::Plug")
  end

  context "plugin is unknown" do
    it "raises an error" do
      expect { Pakyow.app(:test).plugs.foo }.to raise_error(NoMethodError)
    end
  end

  context "plugin mount name is unknown" do
    it "returns nil" do
      expect(Pakyow.app(:test).plugs.testable(:bar)).to be(nil)
    end
  end
end
