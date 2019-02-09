RSpec.shared_examples :connection_body do
  describe "#body" do
    it "returns an empty body by default" do
      expect(connection.body).to be_instance_of(Async::HTTP::Body::Buffered)
      expect(connection.body.read).to be(nil)
    end

    context "after setting" do
      before do
        connection.body = StringIO.new("foo")
      end

      it "returns the wrapped body" do
        expect(connection.body.read).to eq("foo")
      end
    end
  end

  describe "#body=" do
    before do
      connection.body = StringIO.new("foo")
    end

    it "wraps the body" do
      expect(connection.body).to be_instance_of(Async::HTTP::Body::Buffered)
      expect(connection.body.read).to eq("foo")
    end

    context "value is an Async::HTTP::Body" do
      before do
        connection.body = Async::HTTP::Body::Writable.new
      end

      it "does not wrap the body" do
        expect(connection.body).to be_instance_of(Async::HTTP::Body::Writable)
      end
    end
  end
end
