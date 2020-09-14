require "pakyow/support/makeable"

RSpec.describe Pakyow::Support::Makeable do
  shared_examples :making do
    describe ".make" do
      after do
        if defined?(Foo)
          Object.send(:remove_const, :Foo)
        end
      end

      let(:result) {
        object.make(*namespaces, name, **kwargs, &block)
      }

      let(:name) {
        :foo
      }

      let(:namespaces) {
        []
      }

      let(:kwargs) {
        {}
      }

      let(:block) {
        Proc.new {}
      }

      it "sets the object name" do
        expect(result.object_name.name).to eq(:foo)
      end

      it "sets the object namespace" do
        expect(result.object_name.path).to eq("foo")
      end

      it "sets the constant" do
        expect {
          result
        }.to change {
          defined?(Foo)
        }.from(nil).to("constant")
      end

      it "returns the result" do
        expect(result).to eq(Foo)
      end

      it "uses isolable" do
        expect(object).to receive(:isolate).with(object, as: :foo, context: Object, namespace: []).and_call_original

        result
      end

      context "block is passed" do
        let(:block) {
          Proc.new {
            @foo = :bar
          }
        }

        it "evals the block on the result" do
          expect(result.instance_variable_get(:@foo)).to eq(:bar)
        end
      end

      context "name is an ObjectName" do
        let(:name) {
          Pakyow::Support::ObjectName.build(:foo)
        }

        it "sets the object name" do
          expect(result.object_name.name).to eq(:foo)
        end
      end

      describe "setting state on the result" do
        let(:kwargs) {
          { bar: :baz }
        }

        it "sets each arg as a class ivar" do
          expect(result.instance_variable_get(:@bar)).to eq(:baz)
        end
      end

      describe "making the object within a namespace" do
        after do
          if defined?(Foo::Bar::Baz)
            Foo::Bar.send(:remove_const, :Baz)
          end

          if defined?(Foo::Bar)
            Foo.send(:remove_const, :Bar)
          end
        end

        let(:namespaces) {
          [:foo, :bar]
        }

        let(:name) {
          :baz
        }

        it "sets the object name" do
          expect(result.object_name.name).to eq(:baz)
        end

        it "sets the object namespace" do
          expect(result.object_name.path).to eq("foo/bar/baz")
        end

        it "sets the constant" do
          expect {
            result
          }.to change {
            defined?(Foo::Bar::Baz)
          }.from(nil).to("constant")
        end

        context "namespace is an ObjectNamespace" do
          let(:namespaces) {
            [Pakyow::Support::ObjectNamespace.new(:foo, :bar)]
          }

          it "sets the object name" do
            expect(result.object_name.name).to eq(:baz)
          end

          it "sets the object namespace" do
            expect(result.object_name.path).to eq("foo/bar/baz")
          end

          it "sets the constant" do
            expect {
              result
            }.to change {
              defined?(Foo::Bar::Baz)
            }.from(nil).to("constant")
          end

          context "name is an ObjectName" do
            let(:name) {
              Pakyow::Support::ObjectName.build(:baz)
            }

            it "sets the object name" do
              expect(result.object_name.name).to eq(:baz)
            end

            it "sets the object namespace" do
              expect(result.object_name.path).to eq("foo/bar/baz")
            end
          end
        end
      end

      describe "not setting the constant" do
        context "set_const = false" do
          let(:kwargs) {
            {
              set_const: false
            }
          }

          it "does not define a constant" do
            expect {
              result
            }.not_to change {
              defined?(Foo)
            }
          end
        end
      end

      describe "passing the context explicitly" do
        let(:result) {
          object.make(*namespaces, name, context: context, **kwargs, &block)
        }

        let(:context) {
          Class.new
        }

        it "uses isolable correctly" do
          expect(object).to receive(:isolate).with(object, as: :foo, context: context, namespace: []).and_call_original

          result
        end
      end

      describe "defining the same object twice" do
        let(:initial) {
          object.make(*namespaces, name, foo: :bar, &block)
        }

        let(:redefinition) {
          object.make(*namespaces, name, foo: :baz) do
            @bar = :baz
          end
        }

        let(:object) {
          Class.new do
            include Pakyow::Support::Hookable
            include Pakyow::Support::Makeable
          end
        }

        let(:hook_calls) {
          { before: [], after: [] }
        }

        before do
          local = self

          object.before "make" do
            local.hook_calls[:before] << :called
          end

          object.after "make" do
            local.hook_calls[:after] << :called
          end

          initial
        end

        it "sets the given instance variables" do
          expect(redefinition.instance_variable_get(:@foo)).to eq(:baz)
        end

        it "evals the block on the existing object" do
          expect(redefinition.instance_variable_get(:@bar)).to eq(:baz)
        end

        it "does not invoke the make hooks multiple times" do
          redefinition
          expect(hook_calls[:before].count).to eq(1)
          expect(hook_calls[:after].count).to eq(1)
        end
      end
    end
  end

  describe "making a class" do
    before do
      stub_const "MakeableClass", object
    end

    let :object do
      Class.new do
        include Pakyow::Support::Makeable
      end
    end

    include_examples :making

    context "hooking into make" do
      after do
        Object.send(:remove_const, :Foo)
      end

      context "object is hookable" do
        let :object do
          Class.new do
            include Pakyow::Support::Hookable
            include Pakyow::Support::Makeable
          end
        end

        before do
          local = self

          object.before "make" do
            local.instance_variable_set(:@called_before, self.name)
          end

          object.after "make" do
            local.instance_variable_set(:@called_after, self.name)
          end
        end

        it "calls the before make hook" do
          expect {
            object.make(:foo)
          }.to change {
            @called_before
          }.from(nil).to("Foo")
        end

        it "calls the after make hook" do
          expect {
            object.make(:foo)
          }.to change {
            @called_after
          }.from(nil).to("Foo")
        end

        describe "accessing source location in a before make hook" do
          before do
            local = self

            object.before "make" do
              local.instance_variable_set(:@source_location, source_location)
            end
          end

          it "is set" do
            object.make(:foo) do; end
            expect(@source_location).to be_instance_of(Array)
          end
        end

        describe "accessing class level instance state in a before make hook" do
          before do
            local = self

            object.before "make" do
              local.instance_variable_set(:@some_key, @some_key)
            end
          end

          it "is set" do
            expect {
              object.make(:foo, some_key: :some_value)
            }.to change {
              @some_key
            }.from(nil).to(:some_value)
          end
        end
      end
    end
  end

  describe "making a module" do
    before do
      stub_const "MakeableModule", object
    end

    let :object do
      Module.new do
        include Pakyow::Support::Makeable

        def foo
          :foo
        end

        module_function :foo
      end
    end

    include_examples :making

    describe "module inheritence" do
      it "inherits methods from the module" do
        expect(object.foo).to eq(:foo)
      end
    end
  end
end
