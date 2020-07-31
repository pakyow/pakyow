require_relative "shared"

RSpec.describe "introspecting the source location for loaded code" do
  include_context "loader"

  describe "simple definition" do
    let(:loader_path) {
      File.expand_path("../support/source_location/simple.rb", __FILE__)
    }

    it "sets the correct source location" do
      expect(target.state(:foo).method(:test).source_location).to eq([loader_path, 2])
    end
  end

  describe "definition with toplevel comments" do
    let(:loader_path) {
      File.expand_path("../support/source_location/toplevel_comments.rb", __FILE__)
    }

    it "sets the correct source location" do
      expect(target.state(:foo).method(:test).source_location).to eq([loader_path, 12])
    end
  end

  describe "definition with inline comments" do
    let(:loader_path) {
      File.expand_path("../support/source_location/inline_comments.rb", __FILE__)
    }

    it "sets the correct source location" do
      expect(target.state(:foo).method(:test).source_location).to eq([loader_path, 7])
    end
  end
end
