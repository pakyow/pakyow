require "pakyow/validations/length"

RSpec.describe Pakyow::Validations::Length do
  it "is named" do
    expect(described_class.name).to eq(:length)
  end

  describe "message" do
    context "minimium is provided" do
      it "is correct" do
        expect(described_class.message(minimum: 2)).to eq("must have more than 2 characters")
      end

      it "correctly handles 1" do
        expect(described_class.message(minimum: 1)).to eq("must have more than 1 character")
      end
    end

    context "maximum is provided" do
      it "is correct" do
        expect(described_class.message(maximum: 2)).to eq("must have less than 2 characters")
      end

      it "correctly handles 1" do
        expect(described_class.message(maximum: 1)).to eq("must have less than 1 character")
      end
    end

    context "minimium and maximum is provided" do
      it "is correct" do
        expect(described_class.message(minimum: 2, maximum: 5)).to eq("must have between 2 and 5 characters")
      end
    end
  end

  context "minimium is provided" do
    context "value is less than the minimium" do
      it "is invalid" do
        expect(described_class.valid?("a", minimum: 2)).to be(false)
      end
    end

    context "value is equal to the minimium" do
      it "is valid" do
        expect(described_class.valid?("aa", minimum: 2)).to be(true)
      end
    end

    context "value is greater than the minimium" do
      it "is valid" do
        expect(described_class.valid?("aaa", minimum: 2)).to be(true)
      end
    end
  end

  context "maximum is provided" do
    context "value is less than the maximum" do
      it "is valid" do
        expect(described_class.valid?("aa", maximum: 3)).to be(true)
      end
    end

    context "value is equal to the maximum" do
      it "is valid" do
        expect(described_class.valid?("aaa", maximum: 3)).to be(true)
      end
    end

    context "value is greater than the maximum" do
      it "is invalid" do
        expect(described_class.valid?("aaaa", maximum: 3)).to be(false)
      end
    end
  end

  context "minimium and maximum is provided" do
    context "value is less than the minimium" do
      it "is invalid" do
        expect(described_class.valid?("a", minimum: 2, maximum: 4)).to be(false)
      end
    end

    context "value is greater than the maximum" do
      it "is invalid" do
        expect(described_class.valid?("aaaaa", minimum: 2, maximum: 4)).to be(false)
      end
    end

    context "value is between the minimium and maximum" do
      it "is valid" do
        expect(described_class.valid?("aaa", minimum: 2, maximum: 4)).to be(true)
      end
    end
  end
end
