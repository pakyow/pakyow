require "pakyow/support/makeable"

RSpec.describe Pakyow::Support::Makeable do
  shared_examples :making do
    describe ".make" do
      after do
        Object.send(:remove_const, :Foo)
      end

      it "sets the name on the class" do
        expect(object.make(:foo).__object_name.name).to eq(:foo)
      end

      it "evals the block on the class" do
        expect(object.make(:foo) { @foo = :bar }.instance_variable_get(:@foo)).to eq(:bar)
      end

      it "returns the new class" do
        expect(object.make(:foo)).to eq(Foo)
      end

      context "passing arbitrary args" do
        it "sets each arg as a class ivar" do
          expect(object.make(:foo, bar: :baz).instance_variable_get(:@bar)).to eq(:baz)
        end
      end
    end

    describe "the defined class" do
      context "given name is a symbol" do
        after do
          Object.send(:remove_const, :FooBar)
        end

        it "creates a camelized class name" do
          expect(object.make(:foo_bar)).to eq(FooBar)
        end
      end

      context "given name is an instance of ObjectName" do
        context "given name has an underscore" do
          after do
            Object.send(:remove_const, :FooBar)
          end

          let :class_name do
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new,
              :foo_bar
            )
          end

          it "creates a camelized class name" do
            expect(object.make(class_name)).to eq(FooBar)
          end
        end

        context "given name has more than one underscore" do
          after do
            Object.send(:remove_const, :FooBarBaz)
          end

          let :class_name do
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new,
              :foo_bar_baz
            )
          end

          it "creates a camelized class name" do
            expect(object.make(class_name)).to eq(FooBarBaz)
          end
        end
      end

      context "given name is a namespaced instance of ObjectName" do
        context "given name has a single namespace" do
          after do
            Foo.send(:remove_const, :Bar)
            Object.send(:remove_const, :Foo)
          end

          let :class_name do
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new(:foo),
              :bar
            )
          end

          it "creates a namespaced class name" do
            expect(object.make(class_name)).to eq(Foo::Bar)
          end
        end

        context "given name has multiple namespaces" do
          after do
            Foo::Bar.send(:remove_const, :Baz)
            Foo.send(:remove_const, :Bar)
            Object.send(:remove_const, :Foo)
          end

          let :class_name do
            Pakyow::Support::ObjectName.new(
              Pakyow::Support::ObjectNamespace.new(:foo, :bar),
              :baz
            )
          end

          it "creates a namespaced class name" do
            expect(object.make(class_name)).to eq(Foo::Bar::Baz)
          end
        end
      end
    end
  end

  describe "making a class" do
    let :object do
      Class.new do
        extend Pakyow::Support::Makeable
      end
    end

    include_examples :making
  end

  describe "making a module" do
    let :object do
      Module.new do
        extend Pakyow::Support::Makeable
      end
    end

    include_examples :making
  end
end
