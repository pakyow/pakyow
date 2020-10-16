RSpec.shared_examples :connection_authority do
  describe "#authority" do
    it "returns the expected value" do
      expect(connection.authority).to eq("#{subdomain}.#{host}:#{port}")
    end
  end
end
