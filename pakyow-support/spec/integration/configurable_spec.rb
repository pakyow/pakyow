require "pakyow/support/configurable"

RSpec.describe "configuring an object" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable

      def self.name
        :configurable
      end
    end
  end

  it "provides access to a setting defined without a default value" do
    object.setting :foo
    object.configure!
    expect(object.config.foo).to be_nil
  end

  it "provides access to a setting defined with a default value" do
    object.setting :foo, :bar
    object.configure!
    expect(object.config.foo).to be(:bar)
  end

  it "provides access to a setting defined with a block" do
    object.setting :foo do
      :bar
    end

    object.configure!
    expect(object.config.foo).to be(:bar)
  end

  it "provides access to the object being configured" do
    object.setting :name do
      self.name
    end

    object.configure!
    expect(object.config.name).to eq(:configurable)
  end

  it "fails when accessing an unknown setting" do
    object.configure!
    expect { object.config.foo }.to raise_error(RuntimeError)
  end

  it "converts to a hash" do
    object.setting :foo do
      :bar
    end

    object.configure!
    expect(object.config.to_h).to eq({:foo => :bar})
  end

  it "responds to missing" do
    object.settings_for :foo do
      setting :bar, :baz
    end

    object.configure!
    expect(object.config.respond_to?(:foo)).to be(true)
    expect(object.config.respond_to?(:bar)).to be(false)
    expect(object.config.foo.respond_to?(:bar)).to be(true)
    expect(object.config.foo.respond_to?(:baz)).to be(false)
  end
end
