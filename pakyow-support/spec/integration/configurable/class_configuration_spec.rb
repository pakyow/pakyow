require "pakyow/support/configurable"

RSpec.describe "configuring a configurable class" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable

      def self.name
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
      end

      object.configure!
    end

    it "inherits default values when unspecified" do
      expect(object.config.foo).to eq(:foo_global)
    end

    it "overrides default values when specified" do
      expect(object.config.bar).to eq(:bar_default)
    end

    it "provides access to the object being configured" do
      expect(object.config.name).to eq(:configurable)
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

      object.configure! :development
    end

    it "applies the global configuration" do
      expect(object.config.foo).to eq(:foo_global)
    end

    it "overrides globals with values for the environment" do
      expect(object.config.bar).to eq(:bar_development)
    end

    it "does not apply other environments" do
      expect(object.config.baz).to eq(:baz_default)
    end
  end

  describe "configuring with default values" do
    before do
      object.setting :foo
      object.setting :bar
      object.setting :baz
      object.setting :qux

      object.defaults :development do
        setting :foo, :foo_development_default
        setting :bar, :bar_development_default
      end

      object.defaults :production do
        setting :baz, :baz_production_default
      end

      object.defaults :development, :production do
        setting :qux, :qux_multiple
      end

      object.configure :development do
        config.bar = :bar_development
      end

      object.configure! :development
    end

    it "uses the default values for the environment" do
      expect(object.config.foo).to eq(:foo_development_default)
    end

    it "overrides default values" do
      expect(object.config.bar).to eq(:bar_development)
    end

    it "does not use default values for other environments" do
      expect(object.config.baz).to eq(nil)
    end

    it "configures defaults for multiple environments" do
      expect(object.config.qux).to eq(:qux_multiple)
    end
  end

  describe "configuring a subclass of a configurable class" do
    before do
      setup
    end

    def setup
      object.setting :foo, :foo_parent
      object.setting :bar, :bar_parent
      object.configure!

      @subclass = Class.new(object)
      @subclass.setting :bar, :bar_subclass
      @subclass.setting :baz, :baz_subclass
      @subclass.configure!
    end

    it "inherits settings from the parent class" do
      expect(@subclass.config.foo).to eq(:foo_parent)
    end

    it "overrides settings defined on the parent class" do
      expect(@subclass.config.bar).to eq(:bar_subclass)
    end

    it "uses settings default on the subclass" do
      expect(@subclass.config.baz).to eq(:baz_subclass)
    end

    it "does not modify values in the parent class" do
      expect(object.config.foo).to eq(:foo_parent)
      expect(object.config.bar).to eq(:bar_parent)
    end

    context "values are dependent" do
      def setup
        object.setting :foo, "foo_parent"
        object.setting :bar do
          config.foo + "_bar"
        end

        @subclass = Class.new(object)
        @subclass.setting :foo, "foo_subclass"
      end

      it "sets up the context correctly" do
        expect(@subclass.config.bar).to eq("foo_subclass_bar")
      end
    end
  end

  describe "adding a setting to the object's config" do
    before do
      object.config.setting :foo, "foo"
    end

    it "is added to the object" do
      expect(object.config.foo).to eq("foo")
    end
  end

  describe "adding a group to the object's config" do
    before do
      object.configurable :baz do
        setting :qux, "qux"
      end

      object.config.configurable :foo do
        setting :bar, "bar"
      end
    end

    it "is added to the object" do
      expect(object.config.foo.bar).to eq("bar")
    end
  end

  describe "adding a setting directly to an existing group" do
    before do
      object.configurable :foo do
        setting :bar, "bar"
      end

      object.config.foo.configurable :baz do
        setting :qux, "qux"
      end
    end

    it "is added to the object" do
      expect(object.config.foo.baz.qux).to eq("qux")
    end
  end
end
