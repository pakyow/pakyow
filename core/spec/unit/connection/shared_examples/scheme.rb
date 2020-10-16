RSpec.shared_examples :connection_scheme do
  describe "#scheme" do
    it "returns the correct value" do
      expect(connection.scheme).to eq("http")
    end

    context "https header is set" do
      context "value is on" do
        let :headers do
          { "https" => "on" }
        end

        it "returns https" do
          expect(connection.scheme).to eq("https")
        end
      end

      context "value is something other than on" do
        let :headers do
          { "https" => "something other than on" }
        end

        it "returns the request scheme" do
          expect(connection.scheme).to eq("http")
        end
      end
    end

    context "x-forwarded-scheme header is set" do
      let :headers do
        { "x-forwarded-scheme" => "https" }
      end

      it "returns the header value" do
        expect(connection.scheme).to eq("https")
      end
    end

    context "x-forwarded-proto header is set" do
      let :headers do
        { "x-forwarded-proto" => "https" }
      end

      it "returns the header value" do
        expect(connection.scheme).to eq("https")
      end
    end
  end
end
