RSpec.shared_examples :connection_subdomain do
  describe "#subdomain" do
    it "returns the expected value" do
      expect(connection.subdomain).to eq(subdomain)
    end
  end
end
