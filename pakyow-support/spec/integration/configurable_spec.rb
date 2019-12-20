require "pakyow/support/configurable"
require "pakyow/support/deep_freeze"

RSpec.shared_examples "configurable" do
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
    expect { object.config.foo }.to raise_error(NoMethodError)
  end

  it "converts to a hash" do
    object.setting :foo do
      :bar
    end

    object.configure!
    expect(object.config.to_h).to eq({:foo => :bar})
  end

  it "responds to missing" do
    object.configurable :foo do
      setting :bar, :baz
    end

    object.configure!
    expect(object.config.respond_to?(:foo)).to be(true)
    expect(object.config.respond_to?(:bar)).to be(false)
    expect(object.config.foo.respond_to?(:bar)).to be(true)
    expect(object.config.foo.respond_to?(:baz)).to be(false)
  end

  describe "configuring for an environment" do
    before do
      object.setting :foo
      object.setting :bar
      object.setting :baz

      object.configure do
        config.foo = :global_foo
        config.baz = :global_baz
      end

      object.configure :specific do
        config.bar = :bar
        config.baz = :baz
      end

      object.configure :other do
        config.foo = :other_foo
        config.bar = :other_bar
        config.baz = :other_baz
      end

      object.configure!(environment)
    end

    let(:environment) {
      :specific
    }

    it "configures globally" do
      expect(object.config.foo).to eq(:global_foo)
    end

    it "configures for the environment" do
      expect(object.config.bar).to eq(:bar)
    end

    it "gives precedence to the environment" do
      expect(object.config.baz).to eq(:baz)
    end

    context "environment is not a symbol" do
      let(:environment) {
        "specific"
      }

      it "still configures" do
        expect(object.config.foo).to eq(:global_foo)
        expect(object.config.bar).to eq(:bar)
        expect(object.config.baz).to eq(:baz)
      end
    end
  end

  describe "memoization" do
    it "memoizes default values" do
      object.setting :foo, []
      object.configure!

      object.config.foo << :bar
      object.config.foo << :baz

      expect(object.config.foo).to eq([:bar, :baz])
    end

    it "memoizes values provided by blocks" do
      object.setting :foo do
        []
      end

      object.configure!

      object.config.foo << :bar
      object.config.foo << :baz

      expect(object.config.foo).to eq([:bar, :baz])
    end
  end

  describe "freezing" do
    using Pakyow::Support::DeepFreeze

    it "builds each value" do
      object.setting :foo, :bar
      object.configure!
      object.deep_freeze

      expect(object.config.foo).to eq(:bar)
    end
  end
end

RSpec.describe "configuring a class" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable

      def self.name
        :configurable
      end
    end
  end

  include_examples "configurable"
end

RSpec.describe "configuring a module" do
  let :object do
    Module.new do
      include Pakyow::Support::Configurable

      def self.name
        :configurable
      end
    end
  end

  include_examples "configurable"
end
