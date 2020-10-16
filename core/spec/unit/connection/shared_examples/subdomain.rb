RSpec.shared_examples :connection_subdomain do
  describe "#subdomain" do
    it "returns the expected value" do
      expect(connection.subdomain).to eq(subdomain)
    end

    context "multi-level subdomain" do
      let(:subdomain) {
        "dev.www"
      }

      it "returns the expected value" do
        expect(connection.subdomain).to eq(subdomain)
      end
    end

    context "passing tld length" do
      let(:subdomain) {
        "dev.www"
      }

      it "returns the expected value" do
        expect(connection.subdomain(2)).to eq("dev")
      end

      it "memoizes correctly" do
        expect(connection.subdomain(2)).to be(connection.subdomain(2))
        expect(connection.subdomain(2)).not_to eq(connection.subdomain)
      end
    end
  end
end
