require "pakyow/validations/presence"

RSpec.describe Pakyow::Validations::Presence do
  let :validation do
    Pakyow::Validations::Presence
  end

  it "is named" do
    expect(validation.name).to eq(:presence)
  end

  context "value is a non-empty string" do
    it "is valid" do
      expect(validation.valid?("foo")).to be true
    end
  end

  context "value is a non-empty array" do
    it "is valid" do
      expect(validation.valid?([:foo])).to be true
    end
  end

  context "value is a non-empty hash" do
    it "is valid" do
      expect(validation.valid?({ foo: :bar })).to be true
    end
  end

  context "value is an empty string" do
    it "is invalid" do
      expect(validation.valid?("")).to be false
    end
  end

  context "value is a string of whitespace" do
    it "is invalid" do
      expect(validation.valid?("   ")).to be false
    end
  end

  context "value is nil" do
    it "is invalid" do
      expect(validation.valid?(nil)).to be false
    end
  end

  context "value is an empty array" do
    it "is invalid" do
      expect(validation.valid?([])).to be false
    end
  end

  context "value is an empty hash" do
    it "is invalid" do
      expect(validation.valid?({})).to be false
    end
  end
end
