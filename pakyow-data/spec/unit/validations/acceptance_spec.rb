RSpec.describe Pakyow::Data::Validations::Acceptance do
  let :validation do
    Pakyow::Data::Validations::Acceptance
  end

  it "is named" do
    expect(validation.name).to eq(:acceptance)
  end

  context "value is true" do
    it "is valid" do
      expect(validation.valid?(true)).to be true
    end
  end

  context "value is false" do
    it "is invalid" do
      expect(validation.valid?(false)).to be false
    end
  end

  context "with accepts option" do
    context "value matches accepts option" do
      it "is valid" do
        expect(validation.valid?("yes", accepts: "yes")).to be true
      end
    end

    context "value does not match accepts option" do
      it "is invalid" do
        expect(validation.valid?("n", accepts: "yes")).to be false
      end
    end

    context "accepts multiple values" do
      context "value matches one" do
        it "is valid" do
          expect(validation.valid?("yes", accepts: [true, "yes"])).to be true
        end
      end

      context "value matches none" do
        it "is invalid" do
          expect(validation.valid?("false", accepts: [true, "yes"])).to be false
        end
      end
    end
  end
end
