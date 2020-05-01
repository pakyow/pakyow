require "pakyow/support/configurable"

RSpec.describe "configuring an instance of a configurable class" do
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
      object.setting :mutable_default, []

      object.configure do
        config.foo = :foo_global
        config.name = self.name
      end

      object.configure!

      @instance = object.new
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

    it "does not modify the original default value" do
      @instance.config.mutable_default << :foo
      expect(object.config.mutable_default).to eq([])
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

      @instance = object.new
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

      object.configure! :development

      @instance = object.new
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
      object.configure!

      subclass = Class.new(object)
      subclass.setting :bar, :bar_subclass
      subclass.setting :baz, :baz_subclass
      subclass.configure!

      @instance = subclass.new
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

  describe "changing a setting on the class" do
    before do
      object.setting :foo, :foo
      object.configure!

      existing_instance
      existing_instance_with_access.config.foo

      object.config.foo = :bar
    end

    let(:existing_instance_with_access) {
      object.new
    }

    let(:existing_instance) {
      object.new
    }

    let(:new_instance) {
      object.new
    }

    it "is inherited by new instances" do
      expect(new_instance.config.foo).to eq(:bar)
    end

    it "reflects the change on existing instances that have not accessed the setting" do
      expect(existing_instance.config.foo).to eq(:bar)
    end

    it "does not reflect the change on existing instances that have accessed the setting" do
      expect(existing_instance_with_access.config.foo).to eq(:foo)
    end
  end

  describe "adding a group to the class" do
    before do
      object.configurable :foo do
        setting :bar, :bar
      end

      object.configure!

      existing_instance

      object.configurable :bar do
        setting :baz, :baz
      end
    end

    let(:existing_instance) {
      object.new
    }

    let(:new_instance) {
      object.new
    }

    it "is inherited by new instances" do
      expect(new_instance.config.bar.baz).to eq(:baz)
    end

    it "is available to existing instances" do
      expect(new_instance.config.bar.baz).to eq(:baz)
    end
  end

  describe "adding a setting to the instance's config" do
    before do
      instance.config.setting :foo, "foo"
    end

    let(:instance) {
      object.new
    }

    it "is added to the instance" do
      expect(instance.config.foo).to eq("foo")
    end

    it "does not change the class" do
      expect {
        object.config.foo
      }.to raise_error(NoMethodError)
    end
  end

  describe "adding a group to the instance's config" do
    before do
      object.configurable :baz do
        setting :qux, "qux"
      end

      instance.config.configurable :foo do
        setting :bar, "bar"
      end
    end

    let(:instance) {
      object.new
    }

    it "is added to the instance" do
      expect(instance.config.foo.bar).to eq("bar")
    end

    it "does not change the class" do
      expect {
        object.config.foo.bar
      }.to raise_error(NoMethodError)
    end
  end

  describe "adding a setting directly to an existing config group" do
    before do
      object.configurable :foo do
        setting :bar, "bar"
      end

      instance.config.foo.configurable :baz do
        setting :qux, "qux"
      end
    end

    let(:instance) {
      object.new
    }

    it "is added to the instance" do
      expect(instance.config.foo.baz.qux).to eq("qux")
    end
  end
end
