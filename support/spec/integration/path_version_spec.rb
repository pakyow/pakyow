require "pakyow/support/path_version"

RSpec.describe Pakyow::Support::PathVersion do
  describe "::build" do
    it "returns a version built from file digests" do
      expect(
        described_class.build(
          File.expand_path("../path_version", __FILE__),
          File.expand_path("../path_version/support", __FILE__)
        )
      ).to eq("9a8ba4c55539ae6739df90c0b5e58c7feff0dde2")
    end
  end
end
