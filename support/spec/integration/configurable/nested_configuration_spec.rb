require "pakyow/support/configurable"

RSpec.describe "nested configuration" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable
    end
  end

  it "provides access to a nested setting" do
    object.configurable :foo do
      setting :bar, :baz
    end

    object.configure!
    expect(object.config.foo.bar).to eq(:baz)
  end

  it "provides access to a deeply nested setting" do
    object.configurable :foo do
      configurable :bar do
        setting :baz, :qux
      end
    end

    object.configure!
    expect(object.config.foo.bar.baz).to eq(:qux)
  end

  it "converts to a hash" do
    object.configurable :foo do
      configurable :bar do
        setting :baz, :qux
      end
    end

    object.configure!
    expect(object.config.to_h).to eq(:foo => { :bar => { :baz => :qux } })
  end
end
