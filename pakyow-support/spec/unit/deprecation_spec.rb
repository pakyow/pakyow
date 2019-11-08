require "pakyow/support/deprecation"

RSpec.describe Pakyow::Support::Deprecation do
  before do
    stub_const "Foo", Class.new
  end

  let(:instance) {
    described_class.new(*targets, solution: solution)
  }

  let(:targets) {
    [Foo, :bar]
  }

  let(:solution) {
    "use `baz'"
  }

  describe "#to_s" do
    context "deprecating a class method" do
      let(:targets) {
        [Foo, :bar]
      }

      let(:solution) {
        "use `baz'"
      }

      it "returns the expected string" do
        expect(instance.to_s).to eq("`Foo::bar' is deprecated; solution: use `baz'")
      end
    end

    context "deprecating an instance method" do
      let(:targets) {
        [Foo.new, :bar]
      }

      let(:solution) {
        "use `baz'"
      }

      it "returns the expected string" do
        expect(instance.to_s).to eq("`Foo#bar' is deprecated; solution: use `baz'")
      end
    end

    context "deprecating a method by name" do
      let(:targets) {
        [:foo]
      }

      let(:solution) {
        "use `bar'"
      }

      it "returns the expected string" do
        expect(instance.to_s).to eq("`foo' is deprecated; solution: use `bar'")
      end
    end

    context "deprecating a class" do
      let(:targets) {
        [Foo]
      }

      let(:solution) {
        "use `Baz'"
      }

      it "returns the expected string" do
        expect(instance.to_s).to eq("`Foo' is deprecated; solution: use `Baz'")
      end
    end

    context "deprecating something else" do
      let(:targets) {
        ["foo.rb"]
      }

      let(:solution) {
        "rename to `bar.rb'"
      }

      it "returns the expected string" do
        expect(instance.to_s).to eq("`foo.rb' is deprecated; solution: rename to `bar.rb'")
      end
    end

    describe "mutating the return value" do
      before do
        instance.to_s.reverse!
      end

      it "does not affect future return values" do
        expect(instance.to_s).to eq("`Foo::bar' is deprecated; solution: use `baz'")
      end
    end
  end
end
