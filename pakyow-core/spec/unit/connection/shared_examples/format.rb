RSpec.shared_examples :connection_format do
  describe "#format" do
    context "request format is unspecified" do
      it "returns the symbolized format" do
        expect(connection.format).to eq(:html)
      end
    end

    describe "specifying the request format through the path" do
      context "format is known" do
        let :path do
          "/foo.json"
        end

        it "returns the symbolized format" do
          expect(connection.format).to eq(:json)
        end
      end

      context "format is unknown" do
        let :path do
          "/foo.foobar"
        end

        it "returns the symbolized format" do
          expect(connection.format).to eq(:foobar)
        end
      end
    end

    describe "specifying the request format through the accept header" do
      context "format is known" do
        let :headers do
          super().tap do |headers|
            headers["accept"] = "application/json"
          end
        end

        it "returns the symbolized format" do
          expect(connection.format).to eq(:json)
        end
      end

      context "format is unknown" do
        let :headers do
          super().tap do |headers|
            headers["accept"] = "application/foobar"
          end
        end

        it "returns nil" do
          expect(connection.format).to eq(nil)
        end
      end

      context "format is any" do
        let :headers do
          super().tap do |headers|
            headers["accept"] = "*/*"
          end
        end

        it "returns any" do
          expect(connection.format).to eq(:any)
        end
      end

      context "multiple formats are specified through the header" do
        let :headers do
          super().tap do |headers|
            headers["accept"] = "application/json, text/html"
          end
        end

        it "uses the first format" do
          expect(connection.format).to eq(:json)
        end
      end
    end

    context "request format is specified in multiple ways" do
      let :path do
        "/index.html"
      end

      let :headers do
        super().tap do |headers|
          headers["accept"] = "application/json"
        end
      end

      it "gives precedence to the path" do
        expect(connection.format).to eq(:html)
      end
    end
  end

  describe "#format=" do
    context "mime type is known" do
      before do
        connection.format = :json
      end

      it "sets the content-type header" do
        expect(connection.header("content-type")).to eq("application/json")
      end
    end

    context "mime type is unknown" do
      before do
        connection.format = :"???"
      end

      it "sets the format" do
        expect(connection.format).to eq(:"???")
      end

      it "does not set the content-type header" do
        expect(connection.header("content-type")).to be(nil)
      end
    end
  end
end
