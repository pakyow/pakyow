RSpec.shared_examples :connection_ip do
  describe "#ip" do
    it "returns the remote ip address" do
      expect(connection.ip).to eq("127.0.0.1")
    end

    context "x-forwarded-for is set" do
      let :headers do
        super().tap do |headers|
          headers["x-forwarded-for"] = "128.0.0.1"
        end
      end

      it "returns the forwarded ip address" do
        expect(connection.ip).to eq("128.0.0.1")
      end
    end
  end
end
