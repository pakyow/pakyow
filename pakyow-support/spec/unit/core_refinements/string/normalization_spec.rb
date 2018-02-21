require "pakyow/support/core_refinements/string/normalization"

RSpec.describe Pakyow::Support::Refinements::String::Normalization do
  using Pakyow::Support::Refinements::String::Normalization

  describe ".normalize_path" do
    it "normalizes paths" do
      expect(String.normalize_path("foo")).to eq("/foo")
      expect(String.normalize_path("foo/bar")).to eq("/foo/bar")
      expect(String.normalize_path("foo//bar")).to eq("/foo/bar")
      expect(String.normalize_path("foo/bar/")).to eq("/foo/bar")
      expect(String.normalize_path("/foo/bar")).to eq("/foo/bar")
      expect(String.normalize_path("/foo//bar/")).to eq("/foo/bar")
    end

    it "normalizes nil" do
      expect(String.normalize_path(nil)).to eq("/")
    end
  end
end
