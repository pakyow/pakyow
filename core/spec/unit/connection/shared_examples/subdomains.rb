RSpec.shared_examples :connection_subdomains do
  describe "#subdomains" do
    it "returns the expected value" do
      expect(connection.subdomains).to eq(["www"])
    end

    context "multi-level subdomain" do
      let(:subdomain) {
        "dev.www"
      }

      it "returns the expected value" do
        expect(connection.subdomains).to eq(["dev", "www"])
      end
    end

    context "passing tld length" do
      let(:subdomain) {
        "dev.www"
      }

      it "returns the expected value" do
        expect(connection.subdomains(2)).to eq(["dev"])
      end

      it "memoizes correctly" do
        expect(connection.subdomains(2)).to be(connection.subdomains(2))
        expect(connection.subdomains(2)).not_to eq(connection.subdomains)
      end
    end
  end
end
