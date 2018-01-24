RSpec.describe Pakyow::Data::Validations::Acceptance do
  let :validation do
    Pakyow::Data::Validations::Acceptance
  end

  it "is named" do
    expect(validation.name).to eq(:acceptance)
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

  context "with accepts option" do
    context "value matches accepts option" do
      it "is valid" do
        expect(validation.valid?("yes", accepts: "yes")).to be true
      end
    end

    context "value does not matche accepts option" do
      it "is invalid" do
        expect(validation.valid?("n", accepts: "yes")).to be false
      end
    end
  end
end
