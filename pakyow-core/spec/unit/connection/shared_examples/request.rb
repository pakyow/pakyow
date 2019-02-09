RSpec.shared_examples :connection_request do
  describe "#request" do
    it "returns the request" do
      expect(connection.request).to_not be(nil)
    end
  end

  describe "#request_method" do
    it "returns the expected value" do
      expect(connection.request_method).to eq("GET")
    end
  end

  describe "#request_path" do
    it "returns the expected value" do
      expect(connection.request_path).to eq("/?foo=bar")
    end
  end
end
