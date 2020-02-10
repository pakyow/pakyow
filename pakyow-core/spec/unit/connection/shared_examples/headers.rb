RSpec.shared_examples :connection_headers do
  describe "#request_header?" do
    context "request has the header" do
      let :headers do
        { "foo-bar" => "baz" }
      end

      it "returns true" do
        expect(connection.request_header?("foo-bar")).to be(true)
      end

      context "passed a weird header name" do
        it "normalizes" do
          expect(connection.request_header?("fOo-baR")).to be(true)
        end
      end
    end

    context "request does not have the header" do
      it "returns false" do
        expect(connection.request_header?("foo-bar")).to be(false)
      end
    end
  end

  describe "#request_header" do
    context "request has the header" do
      let :headers do
        { "foo-bar" => "baz" }
      end

      it "returns the value" do
        expect(connection.request_header("foo-bar")).to eq(["baz"])
      end

      context "passed a weird header name" do
        it "normalizes" do
          expect(connection.request_header("fOo-baR")).to eq(["baz"])
        end
      end
    end

    context "request does not have the header" do
      it "returns nil" do
        expect(connection.request_header("foo-bar")).to be(nil)
      end
    end
  end

  describe "#header?" do
    context "response has the header" do
      before do
        connection.set_header("foo-bar", "baz")
      end

      it "returns the value" do
        expect(connection.header?("foo-bar")).to be(true)
      end

      context "passed a weird header name" do
        it "normalizes" do
          expect(connection.header?("fOo-baR")).to be(true)
        end
      end
    end

    context "request does not have the header" do
      it "returns nil" do
        expect(connection.header?("foo-bar")).to be(false)
      end
    end
  end

  describe "#header" do
    context "response has the header" do
      before do
        connection.set_header("foo-bar", "baz")
      end

      it "returns the value" do
        expect(connection.header("foo-bar")).to eq("baz")
      end

      context "passed a weird header name" do
        it "normalizes" do
          expect(connection.header("fOo-baR")).to eq("baz")
        end
      end
    end

    context "request does not have the header" do
      it "returns nil" do
        expect(connection.header("foo-bar")).to be(nil)
      end
    end
  end

  describe "#set_header" do
    it "sets the value" do
      connection.set_header("foo-bar", "baz")
      expect(connection.header("foo-bar")).to eq("baz")
    end

    context "passed a weird header name" do
      it "normalizes" do
        connection.set_header("fOo-baR", "baz")
        expect(connection.header("foo-bar")).to eq("baz")
      end
    end

    context "passed a non-string value" do
      it "typecasts to a string" do
        connection.set_header("content-length", 5)
        expect(connection.header("content-length")).to eq("5")
      end
    end

    context "passed an array of non-string values" do
      it "typecasts each value to a string" do
        connection.set_header("content-length", [1, 2, 3])
        expect(connection.header("content-length")).to eq(["1", "2", "3"])
      end
    end
  end

  describe "#set_headers" do
    it "sets each value" do
      connection.set_headers("foo-bar" => "baz", "bar-baz" => "qux")
      expect(connection.header("foo-bar")).to eq("baz")
      expect(connection.header("bar-baz")).to eq("qux")
    end

    context "passed a weird header name" do
      it "normalizes" do
        connection.set_headers("fOo-baR" => "baz", "Bar-BAZ" => "qux")
        expect(connection.header("foo-bar")).to eq("baz")
        expect(connection.header("bar-baz")).to eq("qux")
      end
    end
  end

  describe "#delete_header" do
    context "response has the header" do
      before do
        connection.set_header("foo-bar", "baz")
      end

      it "deletes" do
        connection.delete_header("foo-bar")
        expect(connection.header("foo-bar")).to be(nil)
      end

      context "passed a weird header name" do
        it "normalizes" do
          connection.delete_header("fOo-baR")
          expect(connection.header("foo-bar")).to be(nil)
        end
      end
    end

    context "response does not have the header" do
      it "does not fail" do
        expect {
          connection.delete_header("foo-bar")
        }.not_to raise_error

        expect(connection.header("foo-bar")).to be(nil)
      end
    end
  end
end
