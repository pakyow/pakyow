RSpec.shared_examples :connection_port do
  describe "#port" do
    it "returns the expected value" do
      expect(connection.port).to eq(port)
    end
  end
end
