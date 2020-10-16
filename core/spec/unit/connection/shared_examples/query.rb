RSpec.shared_examples :connection_query do
  describe "#query" do
    it "returns the expected value" do
      expect(connection.query).to eq("foo=bar")
    end
  end
end
