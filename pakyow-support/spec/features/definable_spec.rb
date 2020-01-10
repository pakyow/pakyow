require "pakyow/support/definable"
require "pakyow/support/makeable"

RSpec.describe "defining state via definable" do
  let(:application) {
    application_class.definable :controller, controller
    application_class
  }

  let(:application_class) {
    Class.new.tap do |klass|
      Test.const_set(:Application, klass)
      klass.include Pakyow::Support::Definable
    end
  }

  let(:application_instance) {
    application.new
  }

  let(:controller) {
    Class.new.tap do |klass|
      Test.const_set(:Controller, klass)
    end
  }

  before do
    Object.const_set(:Test, Module.new)
  end

  describe "defining state on the class" do
    let(:class_state) {
      application.controller :foo do
        def foo
          :foo
        end
      end
    }

    it "defines a subclass with the given name" do
      expect(class_state).to be(Test::Application::Controllers::Foo)
      expect(class_state.ancestors).to include(controller)
      expect(class_state.new.foo).to eq(:foo)
    end
  end

  describe "defining state on the instance" do
    let(:instance_state) {
      application_instance.controller :bar do
        def bar
          :bar
        end
      end
    }

    it "defines a subclass with the given name" do
      expect(instance_state).to be(Test::Application::Controllers::Bar)
      expect(instance_state.ancestors).to include(controller)
      expect(instance_state.new.bar).to eq(:bar)
    end
  end

  describe "defining class and instance state" do
    let(:class_state) {
      application.controller :foo do
        def foo
          :foo
        end
      end
    }

    let(:instance_state) {
      application_instance.controller :bar do
        def bar
          :bar
        end
      end
    }

    it "defines the class state" do
      expect(class_state).to be(Test::Application::Controllers::Foo)
      expect(class_state.ancestors).to include(controller)
      expect(class_state.new.foo).to eq(:foo)
    end

    it "defines the instance state" do
      expect(instance_state).to be(Test::Application::Controllers::Bar)
      expect(instance_state.ancestors).to include(controller)
      expect(instance_state.new.bar).to eq(:bar)
    end

    it "does not define instance state on the class" do
      class_state; instance_state

      expect(application.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Foo"
      ])
    end

    it "does not define instance state on future instances" do
      class_state; instance_state

      expect(application.new.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Foo"
      ])
    end

    it "does not define future class state on existing instances" do
      instance_state; class_state

      expect(application_instance.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Bar"
      ])
    end

    context "class and instance state have the same name" do
      before do
        application.controller :foo do
          def foo
            :foo1
          end
        end

        application_instance.controller :foo do
          def foo
            :foo2
          end
        end
      end

      it "gives precedence to instance state" do
        expect(application_instance.controllers(:foo).new.foo).to eq(:foo2)
      end
    end
  end

  describe "defining namespaced state" do
    before do
      application.controller :foo, :bar, :baz do; end
    end

    it "namespaces the state" do
      expect(application.controllers(:foo, :bar, :baz)).to be(Test::Application::Controllers::Foo::Bar::Baz)
    end

    describe "defining state within one of the namespaces" do
      before do
        application.controller :foo, :qux do; end
      end

      it "defines the state correctly" do
        expect(application.controllers(:foo, :qux)).to be(Test::Application::Controllers::Foo::Qux)
        expect(application.controllers(:foo, :qux).ancestors).to include(controller)
      end
    end
  end

  describe "specifying the context for defined state" do
    let(:application) {
      application_class.definable :controller, controller, context: Test::Namespace
      application_class
    }

    before do
      Test.const_set(:Namespace, Module.new)
      application.controller :foo do; end
    end

    it "defines the state in the correct context" do
      expect(application.controllers(:foo)).to be(Test::Namespace::Foo)
    end
  end

  describe "defining state by priority" do
    before do
      application.controller :foo, priority: :low do; end
      application.controller :bar, priority: :high do; end
      application.controller :baz do; end
    end

    it "respects the priority" do
      expect(application.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Bar",
        "Test::Application::Controllers::Baz",
        "Test::Application::Controllers::Foo"
      ])
    end
  end

  describe "defined state introspection" do
    before do
      application.controller :foo do; end
    end

    it "implements object name" do
      expect(application.controllers(:foo).object_name.path).to eq("test/application/controllers/foo")
    end

    it "implements source location" do
      expect(application.controllers(:foo).source_location[0]).to eq(__FILE__)
    end
  end

  describe "defining the same state twice" do
    before do
      application.controller :foo do
        def foo
          :foo
        end
      end

      application.controller :foo do
        def bar
          :bar
        end
      end
    end

    it "extends existing state" do
      expect(application.controllers.definitions.count).to eq(1)
      expect(application.controllers(:foo).new.foo).to eq(:foo)
      expect(application.controllers(:foo).new.bar).to eq(:bar)
    end
  end

  describe "extending the definable with a block" do
    let(:application) {
      application_class.definable :controller, controller do
        class << self
          def foo
            :foo
          end
        end
      end

      application_class
    }

    before do
      application.controller :foo do; end
    end

    it "extends the isolated object" do
      expect(application.controllers(:foo).foo).to eq(:foo)
    end
  end

  describe "building definable arguments" do
    let(:application) {
      application_class.definable :controller, controller, builder: -> (*args, **kwargs) {
        kwargs[:foo] = :bar
        return *args, **kwargs
      }

      application_class
    }

    before do
      application.controller :foo, bar: :baz do; end
    end

    it "uses the argument builder to finalize makeable arguments" do
      expect(application.controllers(:foo).instance_variable_get(:@foo)).to eq(:bar)
      expect(application.controllers(:foo).instance_variable_get(:@bar)).to eq(:baz)
    end
  end

  describe "defining state with keyword arguments" do
    before do
      application.controller :foo, foo: :bar do; end
    end

    it "exposes the keyword arguments as instance variables on the defined state" do
      expect(application.controllers(:foo).instance_variable_get(:@foo)).to eq(:bar)
    end
  end

  describe "defining state with a block" do
    before do
      application.controller :foo do
        def self.foo
          :foo
        end
      end
    end

    it "behaves like a class definition" do
      expect(application.controllers(:foo).foo).to eq(:foo)
    end
  end

  describe "definable object initialization" do
    let(:application) {
      application_class.definable :controller, controller

      local = self
      application_class.define_method :initialize do
        local.instance_variable_set(:@initial_definitions, controllers.definitions.dup)
        controller :bar do; end
        local.instance_variable_set(:@final_definitions, controllers.definitions.dup)
      end

      application_class
    }

    before do
      application.controller :foo do; end
    end

    it "makes defined class state available during initialization" do
      application_instance

      expect(@initial_definitions.map(&:name)).to eq([
        "Test::Application::Controllers::Foo"
      ])
    end

    it "makes defined instance state available immediately" do
      application_instance

      expect(@final_definitions.map(&:name)).to eq([
        "Test::Application::Controllers::Foo",
        "Test::Application::Controllers::Bar"
      ])
    end
  end

  describe "subclassing the definable object" do
    before do
      application.controller :foo do; end
    end

    let(:application_subclass) {
      Class.new(application).tap do |klass|
        Test.const_set(:ApplicationSubclass, klass)
      end
    }

    it "makes existing state available to the subclass" do
      expect(application_subclass.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Foo"
      ])
    end

    context "additional state is defined on the subclass" do
      before do
        application_subclass.controller :bar do; end
      end

      it "makes all state available on the subclass" do
        expect(application_subclass.controllers.each.map(&:name)).to eq([
          "Test::Application::Controllers::Foo",
          "Test::ApplicationSubclass::Controllers::Bar"
        ])
      end

      it "does not define state on the parent" do
        expect(application.controllers.each.map(&:name)).to eq([
          "Test::Application::Controllers::Foo"
        ])
      end
    end

    context "additional state is defined on the parent" do
      before do
        application_subclass
        application.controller :bar do; end
      end

      it "defines the state on the parent" do
        expect(application.controllers.each.map(&:name)).to eq([
          "Test::Application::Controllers::Foo",
          "Test::Application::Controllers::Bar"
        ])
      end

      it "does not define state on the subclass" do
        expect(application_subclass.controllers.each.map(&:name)).to eq([
          "Test::Application::Controllers::Foo"
        ])
      end
    end
  end

  describe "defining state in a definable initialization block" do
    let(:application) {
      application_class.definable :controller, controller

      application_class.define_method :initialize do
        controller :bar do; end
      end

      application_class
    }

    let(:application_instance) {
      application.new do
        controller :baz do; end
      end
    }

    before do
      application.controller :foo do; end
    end

    it "defines the state with the correct precedence" do
      expect(application_instance.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Foo",
        "Test::Application::Controllers::Bar",
        "Test::Application::Controllers::Baz"
      ])
    end
  end

  describe "defining children" do
    before do
      application.controller :foo do
        define :bar do; end
      end
    end

    it "namespaces the child state correctly" do
      expect {
        Test::Application::Controllers::Foo::Bar
      }.not_to raise_error
    end

    it "does not change parent state" do
      expect(application.controllers.each.map(&:name)).to eq([
        "Test::Application::Controllers::Foo"
      ])
    end
  end

  describe "defining children on an anonymous parent" do
    let(:defined_state) {
      application.controller do
        define :bar do
        end

        define :bar do
        end
      end
    }

    it "creates an anonymous child" do
      expect(defined_state.children[0].name).to be(nil)
    end

    it "extends existing named state" do
      expect(defined_state.children.count).to eq(1)
    end
  end

  describe "looking up state" do
    before do
      application.controller :foo do
      end

      application.controller :bar do
      end

      application.controller :baz do
      end
    end

    let(:registry) {
      application.controllers
    }

    it "looks up by type" do
      expect(registry).to be_instance_of(Pakyow::Support::Definable::Registry)
    end

    describe "using the registry" do
      it "exposes name" do
        expect(registry.name).to eq(:controller)
      end

      it "exposes object" do
        expect(registry.object).to be(Test::Application::Controller)
      end

      it "finds a definition by name" do
        expect(registry.find(:bar)).to be(Test::Application::Controllers::Bar)
      end

      it "looks up dynamically by name" do
        expect(registry.bar).to be(Test::Application::Controllers::Bar)
      end

      it "iterates over definitions" do
        registered = []
        registry.each do |definition|
          registered << definition
        end

        expect(registered).to eq([
          Test::Application::Controllers::Foo,
          Test::Application::Controllers::Bar,
          Test::Application::Controllers::Baz
        ])
      end

      it "exposes an enumerator" do
        expect(registry.each.count).to eq(3)
      end

      context "registry defines a lookup function" do
        let(:application) {
          application_class.definable :controller, controller, lookup: -> (app, operation, **values, &block) {
            [app, operation, values, block]
          }

          application_class
        }

        it "uses the lookup function" do
          block = Proc.new do; end
          value = registry.bar(foo: :bar, &block)
          expect(value[0]).to be(Test::Application)
          expect(value[1]).to be(Test::Application::Controllers::Bar)
          expect(value[2]).to eq(foo: :bar)
          expect(value[3]).to be(block)
        end
      end
    end
  end

  describe "defining unnamed state" do
    let(:unnamed_state) {
      application.controller do; end
    }

    it "creates an anonymous object" do
      expect(unnamed_state.name).to be(nil)
    end
  end

  describe "hijacking define!" do
    context "define! called during initialization" do
      let(:application_class) {
        application_class = super()
        application_class.class_eval do
          def initialize(&block)
            @initialized = false
            define!(&block)
            @initialized = true
          end
        end

        application_class
      }

      it "calls define! at the right time" do
        initialized = nil
        application_class.new do
          initialized = @initialized
        end

        expect(initialized).to be(false)
      end

      it "calls define! once" do
        calls = []
        application_class.new do
          calls << Time.now
        end

        expect(calls.count).to eq(1)
      end
    end

    context "initial call to define fails" do
      let(:application_class) {
        application_class = super()
        application_class.class_eval do
          def initialize(&block)
            define!(&block)
          rescue
          end
        end

        application_class
      }

      it "is not called again" do
        calls = []

        begin
          application_class.new do
            calls << Time.now
            fail
          end
        rescue
        end

        expect(calls.count).to eq(1)
      end
    end
  end

  describe "defined children" do
    let(:defined_state) {
      application.controller :foo do
        define :bar do
          define :baz do
          end
        end
      end
    }

    it "returns immediate children" do
      expect(defined_state.children).to include(Test::Application::Controllers::Foo::Bar)
    end

    it "does not return grandchildren" do
      expect(defined_state.children).not_to include(Test::Application::Controllers::Foo::Bar::Baz)
    end
  end

  describe "defined parent" do
    let(:defined_state) {
      application.controller :foo do
        define :bar do
        end
      end
    }

    context "parent is the definable object" do
      it "is nil" do
        expect(defined_state.parent).to be(nil)
      end
    end

    context "parent is defined state" do
      it "is the defined state" do
        expect(defined_state.children[0].parent).to be(Test::Application::Controllers::Foo)
      end
    end
  end
end
