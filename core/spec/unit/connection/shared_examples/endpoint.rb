RSpec.shared_examples :connection_endpoint do
  describe "#endpoint" do
    it "returns an endpoint" do
      expect(connection.endpoint).to be_instance_of(Pakyow::Connection::Endpoint)
    end

    describe "the default endpoint" do
      it "has the expected path" do
        expect(connection.endpoint.path).to eq(connection.path)
      end

      it "has the expected params" do
        expect(connection.endpoint.params).to eq(connection.params)
      end

      it "is frozen" do
        expect(connection.endpoint.frozen?).to be(true)
      end
    end

    context "called multiple times" do
      it "returns the same endpoint object" do
        expect(connection.endpoint).to be(connection.endpoint)
      end
    end
  end
end
