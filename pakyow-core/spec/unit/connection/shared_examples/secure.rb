RSpec.shared_examples :connection_secure do
  describe "#secure?" do
    context "connection is http" do
      let :scheme do
        "http"
      end

      it "returns false" do
        expect(connection.secure?).to be(false)
      end
    end

    context "connection is https" do
      let :scheme do
        "https"
      end

      it "returns true" do
        expect(connection.secure?).to be(true)
      end
    end
  end
end
