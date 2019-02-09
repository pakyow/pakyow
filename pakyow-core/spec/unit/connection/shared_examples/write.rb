RSpec.shared_examples :connection_write do
  describe "#write" do
    before do
      connection.body = Async::HTTP::Body::Writable.new
    end

    it "writes to the body" do
      content = "foo"
      expect(connection.body).to receive(:write).with(content)
      connection.write(content)
    end

    it "is aliased as <<" do
      content = "foo"
      expect(connection.body).to receive(:write).with(content)
      connection << content
    end
  end
end
