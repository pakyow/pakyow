require_relative "shared"

RSpec.describe "loading in the correct lexical scope" do
  include_context "loader"

  describe "constant definition" do
    let(:loader_path) {
      File.expand_path("../support/lexical_scope/constant.rb", __FILE__)
    }

    it "defines constants correctly" do
      expect(target.state(:foo).const_get("FOO")).to eq("foo")
    end
  end

  describe "class definition" do
    let(:loader_path) {
      File.expand_path("../support/lexical_scope/class.rb", __FILE__)
    }

    it "defines classes correctly" do
      expect(target.state(:foo).const_get("Bar")).to eq(Target::States::Foo::Bar)
    end
  end

  describe "using refinements" do
    let(:loader_path) {
      File.expand_path("../support/lexical_scope/refinement.rb", __FILE__)
    }

    it "supports refinements" do
      expect(target.state(:foo).perform(String.new).frozen?).to be(true)
    end
  end

  context "with brackets" do
    let(:loader_path) {
      File.expand_path("../support/lexical_scope/brackets.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state(:foo).const_get("FOO")).to eq("foo")
    end
  end

  context "complex state" do
    let(:loader_path) {
      File.expand_path("../support/lexical_scope/complex.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state(:foo).const_get("FOO")).to eq("foo")
    end
  end

  context "lots of state" do
    let(:loader_path) {
      File.expand_path("../support/lexical_scope/multiple.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state(:foo).const_get("FOO")).to eq("foo")
      expect(target.state(:bar).const_get("BAR")).to eq("bar")
    end
  end
end
