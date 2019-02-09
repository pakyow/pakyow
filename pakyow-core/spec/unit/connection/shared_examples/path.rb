RSpec.shared_examples :connection_path do
  describe "#path" do
    it "returns the expected value" do
      expect(connection.path).to eq(path)
    end
  end
end
