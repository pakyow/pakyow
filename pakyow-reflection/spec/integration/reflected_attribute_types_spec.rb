RSpec.describe "reflected attribute types" do
  include_context "reflectable app"
  include_context "mirror"

  context "input type: text" do
    let :frontend_test_case do
      "types/text"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:string)
    end
  end

  context "input type: radio" do
    let :frontend_test_case do
      "types/radio"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:string)
    end
  end

  context "input type: checkbox" do
    let :frontend_test_case do
      "types/checkbox"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:string)
    end
  end

  context "textarea" do
    let :frontend_test_case do
      "types/textarea"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:string)
    end
  end

  context "select" do
    let :frontend_test_case do
      "types/select"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:string)
    end
  end

  context "input type: date" do
    let :frontend_test_case do
      "types/date"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:date)
    end
  end

  context "input type: time" do
    let :frontend_test_case do
      "types/time"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:time)
    end
  end

  context "input type: datetime-local" do
    let :frontend_test_case do
      "types/datetime-local"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:datetime)
    end
  end

  context "input type: number" do
    let :frontend_test_case do
      "types/number"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:decimal)
    end
  end

  context "input type: range" do
    let :frontend_test_case do
      "types/range"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:decimal)
    end
  end

  context "input name ends with *_at" do
    let :frontend_test_case do
      "types/suffix_at"
    end

    it "discovers the correct type" do
      expect(scope(:post).attributes[0].type).to eq(:datetime)
    end
  end

  context "binding defined twice with different types" do
    let :frontend_test_case do
      "types/multiple"
    end

    it "uses the first defined type" do
      expect(scope(:post).attributes[0].type).to eq(:date)
    end
  end
end
