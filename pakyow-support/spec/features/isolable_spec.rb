require "pakyow/support/isolable"

RSpec.describe "isolating objects" do
  shared_examples "isolable" do
    let(:isolable) {
      Class.new do
        include Pakyow::Support::Isolable
      end
    }

    let(:isolated_state_name) {
      "State"
    }

    before do
      stub_const "IsolableObject", isolable
      stub_const isolated_state_name, object
    end

    it "isolates the object" do
      expect(isolable.isolate(State)).to be(IsolableObject::State)
    end

    context "object is already defined" do
      before do
        stub_const "IsolableObject::State", existing_object
      end

      let(:existing_object) {
        Module.new do
          def self.is_existing_object?
            true
          end
        end
      }

      it "does not redefine the object" do
        isolable.isolate(State)

        expect(IsolableObject::State.is_existing_object?).to be(true)
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
