RSpec.shared_examples :connection_fullpath do
  describe "#fullpath" do
    it "returns the expected value" do
      expect(connection.fullpath).to eq("#{path}#{query}")
    end
  end
end
