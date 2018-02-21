require "pakyow/support/core_refinements/method/introspection"

RSpec.describe Pakyow::Support::Refinements::Method::Introspection do
  using Pakyow::Support::Refinements::Method::Introspection

  describe "#keyword_argument?" do
    context "method accepts no arguments" do
      before do
        def foo
        end
      end

      it "returns false" do
        expect(method(:foo).keyword_argument?(:bar)).to be(false)
      end
    end

    context "method accepts one argument" do
      before do
        def foo(bar)
        end
      end

      it "returns false" do
        expect(method(:foo).keyword_argument?(:bar)).to be(false)
      end
    end

    context "method accepts one keyword argument" do
      before do
        def foo(bar: nil)
        end
      end

      it "returns true when the name matches" do
        expect(method(:foo).keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(method(:foo).keyword_argument?(:baz)).to be(false)
      end
    end

    context "method accepts two arguments, one of them a keyword argument" do
      before do
        def foo(baz, bar: nil)
        end
      end

      it "returns true when the name matches" do
        expect(method(:foo).keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(method(:foo).keyword_argument?(:baz)).to be(false)
      end
    end

    context "method accepts multiple keyword arguments" do
      before do
        def foo(bar: nil, baz: nil)
        end
      end

      it "returns true when the name matches one" do
        expect(method(:foo).keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match either" do
        expect(method(:foo).keyword_argument?(:qux)).to be(false)
      end
    end
  end
end
