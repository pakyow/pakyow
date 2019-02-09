RSpec.shared_examples :connection_scheme do
  describe "#scheme" do
    it "returns the correct value" do
      expect(connection.scheme).to eq("http")
    end
  end
end
