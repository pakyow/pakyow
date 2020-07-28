require_relative "shared"

RSpec.describe "loading definable state" do
  include_context "loader"

  describe "simple definition" do
    let(:loader_path) {
      File.expand_path("../support/definable_state/simple.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state(:foo)).to be(Target::States::Foo)
    end
  end

  describe "single line definition" do
    let(:loader_path) {
      File.expand_path("../support/definable_state/single.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state(:foo)).to be(Target::States::Foo)
    end
  end

  describe "blockless definition" do
    let(:loader_path) {
      File.expand_path("../support/definable_state/blockless.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state(:foo)).to be(Target::States::Foo)
    end
  end

  describe "syntax error" do
    let(:loader_path) {
      File.expand_path("../support/definable_state/syntax_error.rb", __FILE__)
    }

    let(:autoload) {
      false
    }

    it "exposes the error" do
      expect {
        loader.call(target)
      }.to raise_error(SyntaxError)
    end
  end
end
