require "pakyow/support/configurable"

RSpec.describe "configuring an instance of a configurable class" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable

      def name
        :configurable
      end
    end
  end

  describe "configuring globally" do
    before do
      object.setting :foo, :foo_default
      object.setting :bar, :bar_default
      object.setting :name

      object.configure do
        config.foo = :foo_global
        config.name = self.name
        config.setting :extended, true
      end

      @instance = object.new
      @instance.configure!
    end

    it "inherits default values when unspecified" do
      expect(@instance.config.foo).to eq(:foo_global)
    end

    it "overrides default values when specified" do
      expect(@instance.config.bar).to eq(:bar_default)
    end

    it "provides access to the object being configured" do
      expect(@instance.config.name).to eq(:configurable)
    end

    it "allows new settings to be defined during configuration" do
      expect(@instance.config.extended).to eq(true)
    end
  end

  describe "configuring for an environment" do
    before do
      object.setting :foo, :foo_default
      object.setting :bar, :bar_default
      object.setting :baz, :baz_default

      object.configure do
        config.foo = :foo_global
        config.bar = :bar_global
      end

      object.configure :development do
        config.bar = :bar_development
      end

      object.configure :production do
        config.baz = :baz_production
      end

      @instance = object.new
      @instance.configure! :development
    end

    it "applies the global configuration" do
      expect(@instance.config.foo).to eq(:foo_global)
    end

    it "overrides globals with values for the environment" do
      expect(@instance.config.bar).to eq(:bar_development)
    end

    it "does not apply other environments" do
      expect(@instance.config.baz).to eq(:baz_default)
    end
  end

  describe "configuring with default values" do
    before do
      object.setting :foo
      object.setting :bar
      object.setting :baz

      object.defaults :development do
        setting :foo, :foo_development_default
        setting :bar, :bar_development_default
      end

      object.defaults :production do
        setting :baz, :baz_production_default
      end

      object.configure :development do
        config.bar = :bar_development
      end

      @instance = object.new
      @instance.configure! :development
    end

    it "uses the default values for the environment" do
      expect(@instance.config.foo).to eq(:foo_development_default)
    end

    it "overrides default values" do
      expect(@instance.config.bar).to eq(:bar_development)
    end

    it "does not use default values for other environments" do
      expect(@instance.config.baz).to eq(nil)
    end
  end

  describe "configuring a subclass of a configurable class" do
    before do
      object.setting :foo, :foo_parent
      object.setting :bar, :bar_parent

      subclass = Class.new(object)
      subclass.setting :bar, :bar_subclass
      subclass.setting :baz, :baz_subclass

      @instance = subclass.new
      @instance.configure!
    end

    it "inherits settings from the parent class" do
      expect(@instance.config.foo).to eq(:foo_parent)
    end

    it "overrides settings defined on the parent class" do
      expect(@instance.config.bar).to eq(:bar_subclass)
    end

    it "uses settings default on the subclass" do
      expect(@instance.config.baz).to eq(:baz_subclass)
    end

    it "does not modify values in the parent class" do
      expect(object.config.foo).to eq(:foo_parent)
      expect(object.config.bar).to eq(:bar_parent)
    end
  end
end
