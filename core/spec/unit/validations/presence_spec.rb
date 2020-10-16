require "pakyow/validations/presence"

RSpec.describe Pakyow::Validations::Presence do
  it "is named" do
    expect(Pakyow::Validator.validation_objects[:presence]).to be(described_class)
  end

  it "has a message" do
    expect(described_class.message(**{})).to eq("cannot be blank")
  end

  context "value is a non-empty string" do
    it "is valid" do
      expect(described_class.valid?("foo")).to be true
    end
  end

  context "value is a non-empty array" do
    it "is valid" do
      expect(described_class.valid?([:foo])).to be true
    end
  end

  context "value is a non-empty hash" do
    it "is valid" do
      expect(described_class.valid?({ foo: :bar })).to be true
    end
  end

  context "value is an empty string" do
    it "is invalid" do
      expect(described_class.valid?("")).to be false
    end
  end

  context "value is a string of whitespace" do
    it "is invalid" do
      expect(described_class.valid?("   ")).to be false
    end
  end

  context "value is a string containing line breaks" do
    it "is invalid" do
      expect(described_class.valid?("foo\r\nbar")).to be true
    end
  end

  context "value is nil" do
    it "is invalid" do
      expect(described_class.valid?(nil)).to be false
    end
  end

  context "value is an empty array" do
    it "is invalid" do
      expect(described_class.valid?([])).to be false
    end
  end

  context "value is an empty hash" do
    it "is invalid" do
      expect(described_class.valid?({})).to be false
    end
  end
end
