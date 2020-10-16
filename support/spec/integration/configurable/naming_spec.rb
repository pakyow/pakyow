require "pakyow/support/configurable"

RSpec.describe "naming config classes" do
  let :object do
    klass = Class.new

    stub_const "Configurable", klass

    klass.class_eval do
      include Pakyow::Support::Configurable

      configurable :foo do; end
    end

    klass
  end

  before do
    object.configure!
  end

  it "names the root config class" do
    expect(object.config.class).to be(Configurable::Config)
  end

  it "names configurable groups" do
    expect(object.config.foo.class).to be(Configurable::Config::Foo)
  end
end
