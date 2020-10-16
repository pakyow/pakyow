RSpec.shared_examples :connection_close do
  describe "#close" do
    it "closes the body" do
      expect(connection.body).to receive(:close)
      connection.close
    end
  end
end
