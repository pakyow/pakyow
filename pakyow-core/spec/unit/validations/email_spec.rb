require "pakyow/validations/email"

RSpec.describe Pakyow::Validations::Email do
  it "is named" do
    expect(described_class.name).to eq(:email)
  end

  it "has a message" do
    expect(described_class.message(**{})).to eq("must be a valid email address")
  end

  context "value is an email address" do
    it "is valid" do
      expect(described_class.valid?("bryan@bryanp.org")).to be(true)
    end
  end

  context "value is not an email address" do
    it "is invalid" do
      expect(described_class.valid?("bryan@bryanporg")).to be(false)
    end
  end
end
