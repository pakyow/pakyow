require "pakyow/support/path_version"

RSpec.describe Pakyow::Support::PathVersion do
  describe "::build" do
    it "returns a version built from file digests" do
      expect(
        described_class.build(
          File.expand_path("../path_version", __FILE__),
          File.expand_path("../path_version/support", __FILE__)
        )
      ).to eq("a6ad61c82ced604b89cfd32e681abe0d1d94f3cf")
    end
  end
end
