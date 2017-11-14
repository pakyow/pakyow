require "pakyow/support/class_maker"

RSpec.describe Pakyow::Support::ClassMaker do
  let :object do
    Class.new do
      extend Pakyow::Support::ClassMaker
    end
  end

  describe ".make" do
    after do
      Object.send(:remove_const, :Foo)
    end

    it "sets the name on the class" do
      expect(object.make(:foo).name).to eq(:foo)
    end

    it "sets the state on the class" do
      expect(object.make(:foo, state: [0, 1, 2]).state).to eq([0, 1, 2])
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
    context "given name has an underscore" do
      after do
        Object.send(:remove_const, :FooBar)
      end

      it "is camelcased" do
        expect(object.make(:foo_bar)).to eq(FooBar)
      end
    end

    context "given name has more than one underscore" do
      after do
        Object.send(:remove_const, :FooBarBaz)
      end

      it "is camelcased" do
        expect(object.make(:foo_bar_baz)).to eq(FooBarBaz)
      end
    end

    context "given name has a double underscore" do
      after do
        Foo.send(:remove_const, :Bar)
        Object.send(:remove_const, :Foo)
      end

      it "is namespaced" do
        expect(object.make(:foo__bar)).to eq(Foo::Bar)
      end
    end

    context "given name has more than one double underscore" do
      after do
        Foo::Bar.send(:remove_const, :Baz)
        Foo.send(:remove_const, :Bar)
        Object.send(:remove_const, :Foo)
      end

      it "is namespaced" do
        expect(object.make(:foo__bar__baz)).to eq(Foo::Bar::Baz)
      end
    end

    context "given name has a double underscore followed by a single underscore" do
      after do
        Foo.send(:remove_const, :BarBaz)
        Object.send(:remove_const, :Foo)
      end

      it "is namespaced" do
        expect(object.make(:foo__bar_baz)).to eq(Foo::BarBaz)
      end
    end

    context "given name has a single underscore followed by a double underscore" do
      after do
        FooBar.send(:remove_const, :Baz)
        Object.send(:remove_const, :FooBar)
      end

      it "camelcases the namespace" do
        expect(object.make(:foo_bar__baz)).to eq(FooBar::Baz)
      end
    end
  end
end
