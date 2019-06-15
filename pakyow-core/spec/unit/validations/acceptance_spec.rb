require "pakyow/validations/acceptance"

RSpec.describe Pakyow::Validations::Acceptance do
  it "is named" do
    expect(described_class.name).to eq(:acceptance)
  end

  it "has a message" do
    expect(described_class.message(**{})).to eq("must be accepted")
  end

  context "value is true" do
    it "is valid" do
      expect(described_class.valid?(true)).to be true
    end
  end

  context "value is false" do
    it "is invalid" do
      expect(described_class.valid?(false)).to be false
    end
  end

  context "with accepts option" do
    context "value matches accepts option" do
      it "is valid" do
        expect(described_class.valid?("yes", accepts: "yes")).to be true
      end
    end

    context "value does not match accepts option" do
      it "is invalid" do
        expect(described_class.valid?("n", accepts: "yes")).to be false
      end
    end

    context "accepts multiple values" do
      context "value matches one" do
        it "is valid" do
          expect(described_class.valid?("yes", accepts: [true, "yes"])).to be true
        end
      end

      context "value matches none" do
        it "is invalid" do
          expect(described_class.valid?("false", accepts: [true, "yes"])).to be false
        end
      end
    end
  end
end
