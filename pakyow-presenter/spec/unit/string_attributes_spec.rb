RSpec.describe Pakyow::Presenter::StringAttributes do
  describe "#initialize" do
    it "initializes with a hash" do
      expect(Pakyow::Presenter::StringAttributes.new({})).to be_instance_of(Pakyow::Presenter::StringAttributes)
    end
  end

  let :attributes do
    Pakyow::Presenter::StringAttributes.new(name: "foo", title: "bar")
  end

  describe "#keys" do
    it "delegates to the internal hash" do
      expect(attributes.attributes_hash).to receive(:keys)
      attributes.keys
    end
  end

  describe "#key?" do
    it "delegates to the internal hash" do
      expect(attributes.attributes_hash).to receive(:key?).with(:name)
      attributes.key?(:name)
    end
  end

  describe "#[]" do
    it "delegates to the internal hash" do
      expect(attributes.attributes_hash).to receive(:[]).with(:name)
      attributes[:name]
    end
  end

  describe "#[]=" do
    it "delegates to the internal hash" do
      expect(attributes.attributes_hash).to receive(:[]=).with(:name, "baz")
      attributes[:name] = "baz"
    end
  end

  describe "#delete" do
    it "delegates to the internal hash" do
      expect(attributes.attributes_hash).to receive(:delete).with(:name)
      attributes.delete(:name)
    end
  end

  describe "#each" do
    it "delegates to the internal hash" do
      expect(attributes.attributes_hash).to receive(:each)
      attributes.each
    end
  end

  describe "#==" do
    it "returns true when the objects are equal" do
      other = Pakyow::Presenter::StringAttributes.new(name: "foo", title: "bar")
      expect(attributes).to eq(other)
    end

    it "returns false when the objects are not equal" do
      other = Pakyow::Presenter::StringAttributes.new(name: "foo", title: "baz")
      expect(attributes).not_to eq(other)
    end

    it "returns false when the other object is not of type StringAttributes" do
      other = 'name="foo" title="bar"'
      expect(attributes).not_to eq(other)
    end
  end

  describe "#to_s" do
    it "returns the attributes as a string" do
      expect(attributes.to_s).to eq(' name="foo" title="bar"')
    end

    it "returns an empty string when no attributes" do
      expect(Pakyow::Presenter::StringAttributes.new({}).to_s).to eq("")
    end
  end
end
