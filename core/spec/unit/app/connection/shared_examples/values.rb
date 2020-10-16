RSpec.shared_examples :connection_values do
  describe "#set" do
    before do
      connection.set(:foo, "bar")
    end

    it "sets a value by key" do
      expect(connection.get(:foo)).to eq("bar")
    end

    context "value is already set for key" do
      before do
        connection.set(:foo, "baz")
      end

      it "overrides the value" do
        expect(connection.get(:foo)).to eq("baz")
      end
    end

    context "key is a string" do
      before do
        connection.set("foo", "bar")
      end

      it "sets the value consistently" do
        expect(connection.get(:foo)).to eq("bar")
      end
    end
  end

  describe "#set?" do
    context "value is set for key" do
      before do
        connection.set(:foo, "bar")
      end

      it "returns true" do
        expect(connection.set?(:foo)).to be(true)
      end

      context "key is a string" do
        it "returns true" do
          expect(connection.set?("foo")).to be(true)
        end
      end
    end

    context "value is not set for key" do
      it "returns false" do
        expect(connection.set?(:foo)).to be(false)
      end
    end
  end

  describe "#get" do
    before do
      connection.set(:foo, "bar")
    end

    it "gets a value by key" do
      expect(connection.get(:foo)).to eq("bar")
    end

    context "key is a string" do
      it "gets the value" do
        expect(connection.get("foo")).to eq("bar")
      end
    end

    context "value is not set for key" do
      it "returns nil" do
        expect(connection.get(:bar)).to be(nil)
      end
    end
  end
end
