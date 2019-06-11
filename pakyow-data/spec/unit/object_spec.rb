RSpec.describe Pakyow::Data::Object do
  let :instance do
    described_class.new(foo: "bar")
  end

  describe "#include?" do
    context "value is included for key" do
      it "returns true" do
        expect(instance.include?(:foo)).to be(true)
      end
    end

    context "value is not included for key" do
      it "returns false" do
        expect(instance.include?(:bar)).to be(false)
      end
    end
  end

  describe "#key?" do
    context "value is included for key" do
      it "returns true" do
        expect(instance.key?(:foo)).to be(true)
      end
    end

    context "value is not included for key" do
      it "returns false" do
        expect(instance.key?(:bar)).to be(false)
      end
    end
  end
end
