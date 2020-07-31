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

  describe "unnamed definition" do
    let(:loader_path) {
      File.expand_path("../support/definable_state/unnamed.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state.definitions[0].ancestors).to include(state_class)
    end
  end

  describe "empty definition" do
    let(:loader_path) {
      File.expand_path("../support/definable_state/empty.rb", __FILE__)
    }

    it "defines correctly" do
      expect(target.state.definitions).to be_empty
    end
  end

  describe "unnamed target" do
    let(:target) {
      Class.new(super())
    }

    let(:autoload) {
      false
    }

    let(:loader_path) {
      File.expand_path("../support/definable_state/simple.rb", __FILE__)
    }

    it "raises an error" do
      expect {
        loader.call(target)
      }.to raise_error(ArgumentError) do |error|
        expect(error.message).to include("on unnamed target (`#{target}')")
      end
    end
  end
end
