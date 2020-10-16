require "pakyow/support/isolable"

RSpec.describe "isolating objects" do
  shared_examples "isolable" do
    let(:isolable) {
      isolable = Class.new do
        include Pakyow::Support::Isolable
      end

      stub_const "IsolableObject", isolable

      isolable
    }

    let(:isolated_state_name) {
      "State"
    }

    before do
      stub_const isolated_state_name, object
    end

    it "isolates the object" do
      expect(isolable.isolate(State)).to be(IsolableObject::State)
    end

    it "assigns the object name" do
      object_name = isolable.isolate(State).instance_variable_get(:@object_name)
      expect(object_name).to be_instance_of(Pakyow::Support::ObjectName)
      expect(object_name.path).to eq("state")
    end

    context "object is already defined" do
      before do
        isolable

        stub_const "IsolableObject::State", existing_object
      end

      let(:existing_object) {
        Module.new do
          def self.existing_object?
            true
          end
        end
      }

      it "does not redefine the object" do
        isolable.isolate(State)

        expect(IsolableObject::State.existing_object?).to be(true)
      end
    end

    describe "passing a symbol representing the isolated const" do
      it "isolates the object" do
        expect(isolable.isolate(:state)).to be(IsolableObject::State)
      end
    end

    describe "isolating with a block" do
      before do
        isolable.isolate(State) do
          def self.some_extended_behavior; end
        end
      end

      it "extends the isolated object with the block" do
        expect(isolable.isolated(:State)).to respond_to(:some_extended_behavior)
      end

      it "does not change the parent object" do
        expect(State).not_to respond_to(:some_extended_behavior)
      end
    end

    describe "isolating within another context" do
      before do
        stub_const "FooBarBaz", Module.new
      end

      it "isolates the object" do
        expect(isolable.isolate(State, context: FooBarBaz)).to be(FooBarBaz::State)
      end
    end

    describe "passing the isolated object name" do
      it "isolates the object" do
        expect(isolable.isolate(State, as: :foo_state)).to be(IsolableObject::FooState)
      end
    end

    describe "isolating a namespaced object" do
      let(:isolated_state_name) {
        "Foo::Bar::State"
      }

      it "isolates the object" do
        expect(isolable.isolate(Foo::Bar::State)).to be(IsolableObject::State)
      end
    end

    describe "isolating an object within a namespace" do
      it "isolates the object" do
        expect(isolable.isolate(State, namespace: [:foo, :bar])).to be(IsolableObject::Foo::Bar::State)
      end

      context "namespace is an ObjectNamespace" do
        it "isolates the object" do
          expect(isolable.isolate(State, namespace: Pakyow::Support::ObjectNamespace.new(:foo, :bar))).to be(IsolableObject::Foo::Bar::State)
        end
      end
    end

    describe "getting the isolated object" do
      shared_examples "gettable" do
        def isolate_object
          isolable.isolate(State)
        end

        def get_isolated_object
          context.isolated(:State)
        end

        let(:context) {
          isolable
        }

        it "gets the isolated object" do
          isolate_object

          expect(get_isolated_object).to be(IsolableObject::State)
        end

        context "block is passed" do
          def isolate_object
            isolable.isolate(State) do
              def self.extended_through_isolated; end
            end
          end

          it "extends the isolated object" do
            isolate_object

            expect(get_isolated_object).to respond_to(:extended_through_isolated)
          end
        end

        context "isolated within a context" do
          before do
            stub_const "FooBarBaz", Module.new
          end

          def isolate_object
            isolable.isolate(State, context: FooBarBaz)
          end

          def get_isolated_object
            context.isolated(:State, context: FooBarBaz)
          end

          it "gets the isolated object" do
            isolate_object

            expect(get_isolated_object).to be(FooBarBaz::State)
          end
        end
      end

      it_behaves_like "gettable"

      context "through the instance" do
        it_behaves_like "gettable" do
          let(:context) {
            isolable.new
          }
        end
      end
    end

    describe "checking if an object is isolated" do
      before do
        isolate
      end

      def isolate
        isolable.isolate(State)
      end

      it "detects the isolated object" do
        expect(isolable.isolated?(:State)).to be(true)
      end

      context "with a downcased symbol" do
        it "detects the isolated object" do
          expect(isolable.isolated?(:state)).to be(true)
        end
      end

      context "isolated within another context" do
        def isolate
          stub_const "FooBarBaz", Module.new
          isolable.isolate(State, context: FooBarBaz)
        end

        it "detects the isolated object" do
          expect(isolable.isolated?(:State, context: FooBarBaz)).to be(true)
        end
      end

      context "isolating a namespaced object" do
        let(:isolated_state_name) {
          "Foo::Bar::State"
        }

        def isolate
          isolable.isolate(Foo::Bar::State)
        end

        it "detects the isolated object" do
          expect(isolable.isolated?(:State)).to be(true)
        end
      end

      context "isolating an object within a namespace" do
        def isolate
          isolable.isolate(State, namespace: [:foo, :bar])
        end

        it "detects the isolated object" do
          expect(isolable.isolated?(State, namespace: [:foo, :bar])).to be(true)
        end

        context "namespace is an ObjectNamespace" do
          def isolate
            isolable.isolate(State, namespace: Pakyow::Support::ObjectNamespace.new(:foo, :bar))
          end

          it "detects the isolated object" do
            expect(isolable.isolated?(State, namespace: Pakyow::Support::ObjectNamespace.new(:foo, :bar))).to be(true)
          end
        end
      end
    end

    describe "all the ways to name an isolated object" do
      context "given name is nil" do
        it "is anonymous" do
          expect(isolable.isolate(State, as: nil).name).to be(nil)
        end
      end

      context "given name is a symbol" do
        it "creates a camelized class name" do
          expect(isolable.isolate(State, as: :foo_state)).to be(IsolableObject::FooState)
        end
      end

      context "given name is an instance of ObjectName" do
        context "given name has an underscore" do
          let (:class_name) {
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new,
              :foo_bar
            )
          }

          it "creates a camelized class name" do
            expect(isolable.isolate(State, as: class_name)).to be(IsolableObject::FooBar)
          end
        end

        context "given name has more than one underscore" do
          let(:class_name) {
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new,
              :foo_bar_baz
            )
          }

          it "creates a camelized class name" do
            expect(isolable.isolate(State, as: class_name)).to be(IsolableObject::FooBarBaz)
          end
        end
      end

      context "given name is a namespaced instance of ObjectName" do
        context "given name has a single namespace" do
          let(:class_name) {
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new(:foo),
              :bar
            )
          }

          it "creates a namespaced class name" do
            expect(isolable.isolate(State, as: class_name)).to be(IsolableObject::Foo::Bar)
          end
        end

        context "given name has multiple namespaces" do
          let(:class_name) {
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new(:foo, :bar),
              :baz
            )
          }

          it "creates a namespaced class name" do
            expect(isolable.isolate(State, as: class_name)).to be(IsolableObject::Foo::Bar::Baz)
          end
        end
      end

      context "given name is a root path" do
        it "creates a camelized class name" do
          expect(isolable.isolate(State, as: "/")).to be(IsolableObject::Index)
        end
      end

      context "given name is a path with a simple part" do
        it "creates a camelized class name" do
          expect(isolable.isolate(State, as: "/foo")).to be(IsolableObject::Foo)
        end
      end

      context "given name is a path with multiple parts" do
        it "creates a camelized class name" do
          expect(isolable.isolate(State, as: "/foo/bar")).to be(IsolableObject::Foo::Bar)
        end
      end

      context "given name is oddly constructed" do
        it "creates a camelized class name" do
          expect(isolable.isolate(State, as: "/foo/bar-baz")).to be(IsolableObject::Foo::BarBaz)
        end
      end
    end

    describe "all the ways to get an isolated object" do
      context "with an object name" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:foo)
        }

        context "isolated object exists" do
          let!(:isolated) {
            isolable.isolate(State, as: :foo)
          }

          it "returns the isolated object" do
            expect(isolable.isolated(object_name)).to be(isolated)
          end
        end

        context "isolated object does not exist" do
          it "returns nil" do
            expect(isolable.isolated(object_name)).to be(nil)
          end
        end
      end

      context "with a namespaced object name" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:foo, :bar, :baz)
        }

        context "isolated object exists" do
          let!(:isolated) {
            isolable.isolate(State, as: :baz, namespace: [:foo, :bar])
          }

          it "returns the isolated object" do
            expect(isolable.isolated(object_name)).to be(isolated)
          end
        end

        context "isolated object does not exist" do
          it "returns nil" do
            expect(isolable.isolated(object_name)).to be(nil)
          end
        end
      end

      context "with an object name and an object namespace" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:baz)
        }

        let(:object_namespace) {
          Pakyow::Support::ObjectNamespace.build(:foo, :bar)
        }

        context "isolated object exists" do
          let!(:isolated) {
            isolable.isolate(State, as: :baz, namespace: [:foo, :bar])
          }

          it "returns the isolated object" do
            expect(isolable.isolated(object_name, namespace: object_namespace)).to be(isolated)
          end
        end

        context "isolated object does not exist" do
          it "returns nil" do
            expect(isolable.isolated(object_name, namespace: object_namespace)).to be(nil)
          end
        end
      end

      context "with a namespaced object name and an object namespace" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:baz, :qux)
        }

        let(:object_namespace) {
          Pakyow::Support::ObjectNamespace.build(:foo, :bar)
        }

        context "isolated object exists" do
          let!(:isolated) {
            isolable.isolate(State, as: :qux, namespace: [:foo, :bar, :baz])
          }

          it "returns the isolated object" do
            expect(isolable.isolated(object_name, namespace: object_namespace)).to be(isolated)
          end
        end

        context "isolated object does not exist" do
          it "returns nil" do
            expect(isolable.isolated(object_name, namespace: object_namespace)).to be(nil)
          end
        end
      end
    end

    describe "all the ways to check for an isolated object" do
      context "with an object name" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:foo)
        }

        context "object is isolated" do
          let!(:isolated) {
            isolable.isolate(State, as: :foo)
          }

          it "returns true" do
            expect(isolable.isolated?(object_name)).to be(true)
          end
        end

        context "object is not isolated" do
          it "returns false" do
            expect(isolable.isolated?(object_name)).to be(false)
          end
        end
      end

      context "with a namespaced object name" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:foo, :bar, :baz)
        }

        context "object is isolated" do
          let!(:isolated) {
            isolable.isolate(State, as: :baz, namespace: [:foo, :bar])
          }

          it "returns true" do
            expect(isolable.isolated?(object_name)).to be(true)
          end
        end

        context "object is not isolated" do
          it "returns false" do
            expect(isolable.isolated?(object_name)).to be(false)
          end
        end
      end

      context "with an object name and an object namespace" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:baz)
        }

        let(:object_namespace) {
          Pakyow::Support::ObjectNamespace.build(:foo, :bar)
        }

        context "isolated object exists" do
          let!(:isolated) {
            isolable.isolate(State, as: :baz, namespace: [:foo, :bar])
          }

          it "returns true" do
            expect(isolable.isolated?(object_name, namespace: object_namespace)).to be(true)
          end
        end

        context "isolated object does not exist" do
          it "returns false" do
            expect(isolable.isolated?(object_name, namespace: object_namespace)).to be(false)
          end
        end
      end

      context "with a namespaced object name and an object namespace" do
        let(:object_name) {
          Pakyow::Support::ObjectName.build(:baz, :qux)
        }

        let(:object_namespace) {
          Pakyow::Support::ObjectNamespace.build(:foo, :bar)
        }

        context "isolated object exists" do
          let!(:isolated) {
            isolable.isolate(State, as: :qux, namespace: [:foo, :bar, :baz])
          }

          it "returns true" do
            expect(isolable.isolated?(object_name, namespace: object_namespace)).to be(true)
          end
        end

        context "isolated object does not exist" do
          it "returns false" do
            expect(isolable.isolated?(object_name, namespace: object_namespace)).to be(false)
          end
        end
      end
    end

    describe "isolating within an anonymous parent" do
      let(:isolable) {
        Class.new do
          include Pakyow::Support::Isolable
        end
      }

      it "creates an anonymous child" do
        expect(isolable.isolate(State, as: :baz, namespace: [:foo, :bar]).name).to be(nil)
      end

      it "sets the object name" do
        expect(isolable.isolate(State, as: :baz, namespace: [:foo, :bar]).instance_variable_get(:@object_name).constant).to eq("Foo::Bar::Baz")
      end
    end

    describe "isolating within a nil context" do
      it "creates an anonymous child" do
        expect(isolable.isolate(State, context: nil, as: :baz, namespace: [:foo, :bar]).name).to be(nil)
      end

      it "sets the object name" do
        expect(isolable.isolate(State, as: :baz, namespace: [:foo, :bar]).instance_variable_get(:@object_name).constant).to eq("Foo::Bar::Baz")
      end
    end

    describe "overriding the isolable context" do
      let(:isolable) {
        isolable = Class.new do
          include Pakyow::Support::Isolable

          class << self
            attr_writer :context

            private def isolable_context
              @context
            end
          end
        end

        isolable.context = other_context

        stub_const "IsolableObject", isolable

        isolable
      }

      let(:other_context) {
        stub_const "OtherContext", Module.new
      }

      def isolate
        isolable.isolate(State)
      end

      it "isolates state in the correct context" do
        expect(isolate).to be(OtherContext::State)
        expect(defined?(IsolableObject::State)).to be(nil)
      end

      it "discovers isolated state in the correct context" do
        isolate

        expect(isolable.isolated?(:State)).to be(true)
      end

      it "returns isolated state in the correct context on a class" do
        isolate

        expect(isolable.isolated(:State)).to be(OtherContext::State)
      end

      it "returns isolated state in the correct context on an instance" do
        isolate

        expect(isolable.new.isolated(:State)).to be(OtherContext::State)
      end
    end
  end

  context "object is a class" do
    let(:object) {
      Class.new
    }

    it_behaves_like "isolable"
  end

  context "object is a module" do
    let(:object) {
      Module.new do
        extend Pakyow::Support::Extension

        class_methods do
          def foo; end
        end

        include IncludedModule
        extend ExtendedModule
      end
    }

    let(:extended_module) {
      Module.new do
        def baz; end
      end
    }

    let(:included_module) {
      Module.new do
        def bar; end
      end
    }

    before do
      stub_const "ExtendedModule", extended_module
      stub_const "IncludedModule", included_module
    end

    it_behaves_like "isolable" do
      it "correctly inherits defined extension behavior" do
        klass = Class.new
        klass.include isolable.isolate(State)
        expect(klass).to respond_to(:foo)
      end

      it "extends the isolated object with other extended modules" do
        expect(isolable.isolate(State)).to respond_to(:baz)
      end

      it "includes other included modules into the isolated object" do
        klass = Class.new
        klass.include isolable.isolate(State)
        expect(klass.new).to respond_to(:bar)
      end
    end
  end
end
