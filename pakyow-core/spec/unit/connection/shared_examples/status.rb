RSpec.shared_examples :connection_status do
  describe "#status" do
    it "returns the current status" do
      expect(connection.status).to eq(200)
    end
  end

  describe "#status=" do
    it "sets the status" do
      connection.status = 500
      expect(connection.status).to eq(500)
    end

    context "passed a symbol" do
      it "looks up and sets the status" do
        connection.status = :not_found
        expect(connection.status).to eq(404)
      end
    end
  end
end
