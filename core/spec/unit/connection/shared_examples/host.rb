RSpec.shared_examples :connection_host do
  describe "#host" do
    it "returns the expected value" do
      expect(connection.host).to eq("#{subdomain}.#{host}")
    end
  end
end
