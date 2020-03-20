require "pakyow/support/core_refinements/unbound_method/introspection"

RSpec.describe Pakyow::Support::Refinements::UnboundMethod::Introspection do
  using Pakyow::Support::Refinements::UnboundMethod::Introspection

  describe "#keyword_argument?" do
    context "method accepts no arguments" do
      before do
        def foo
        end
      end

      it "returns false" do
        expect(method(:foo).unbind.keyword_argument?(:bar)).to be(false)
      end
    end

    context "method accepts one argument" do
      before do
        def foo(bar)
        end
      end

      it "returns false" do
        expect(method(:foo).unbind.keyword_argument?(:bar)).to be(false)
      end
    end

    context "method accepts one keyword argument" do
      before do
        def foo(bar: nil)
        end
      end

      it "returns true when the name matches" do
        expect(method(:foo).unbind.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(method(:foo).unbind.keyword_argument?(:baz)).to be(false)
      end
    end

    context "method accepts two arguments, one of them a keyword argument" do
      before do
        def foo(baz, bar: nil)
        end
      end

      it "returns true when the name matches" do
        expect(method(:foo).unbind.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(method(:foo).unbind.keyword_argument?(:baz)).to be(false)
      end
    end

    context "method accepts multiple keyword arguments" do
      before do
        def foo(bar: nil, baz: nil)
        end
      end

      it "returns true when the name matches one" do
        expect(method(:foo).unbind.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match either" do
        expect(method(:foo).unbind.keyword_argument?(:qux)).to be(false)
      end
    end

    context "method requires a keyword argument" do
      before do
        def foo(bar:)
        end
      end

      it "returns true when the name matches" do
        expect(method(:foo).unbind.keyword_argument?(:bar)).to be(true)
      end

      it "returns false when the name does not match" do
        expect(method(:foo).unbind.keyword_argument?(:baz)).to be(false)
      end
    end
  end

  describe "#keyword_arguments?" do
    context "method accepts no arguments" do
      before do
        def foo
        end
      end

      it "returns false" do
        expect(method(:foo).unbind.keyword_arguments?).to be(false)
      end
    end

    context "method accepts one argument" do
      before do
        def foo(bar)
        end
      end

      it "returns false" do
        expect(method(:foo).unbind.keyword_arguments?).to be(false)
      end
    end

    context "method accepts one keyword argument" do
      before do
        def foo(bar: nil)
        end
      end

      it "returns true" do
        expect(method(:foo).unbind.keyword_arguments?).to be(true)
      end
    end

    context "method accepts two arguments, one of them a keyword argument" do
      before do
        def foo(baz, bar: nil)
        end
      end

      it "returns true" do
        expect(method(:foo).unbind.keyword_arguments?).to be(true)
      end
    end

    context "method accepts multiple keyword arguments" do
      before do
        def foo(bar: nil, baz: nil)
        end
      end

      it "returns true" do
        expect(method(:foo).unbind.keyword_arguments?).to be(true)
      end
    end

    context "method requires a keyword argument" do
      before do
        def foo(bar:)
        end
      end

      it "returns true" do
        expect(method(:foo).unbind.keyword_arguments?).to be(true)
      end
    end
  end

  describe "#argument_list?" do
    context "method accepts no arguments" do
      before do
        def foo
        end
      end

      it "returns false" do
        expect(method(:foo).unbind.argument_list?).to be(false)
      end
    end

    context "method accepts one argument" do
      before do
        def foo(bar)
        end
      end

      it "returns true" do
        expect(method(:foo).unbind.argument_list?).to be(true)
      end
    end

    context "method accepts one keyword argument" do
      before do
        def foo(bar: nil)
        end
      end

      it "returns false" do
        expect(method(:foo).unbind.argument_list?).to be(false)
      end
    end

    context "method accepts two arguments, one of them a keyword argument" do
      before do
        def foo(baz, bar: nil)
        end
      end

      it "returns true" do
        expect(method(:foo).unbind.argument_list?).to be(true)
      end
    end
  end
end
