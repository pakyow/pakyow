RSpec.describe Pakyow::Error do
  describe "#url" do
    it "provides a default value"
  end

  describe "#message" do
    it "provides a default value"
  end

  describe "#name" do
    it "defaults to a human version of the class"
  end

  describe "#details" do
    context "error occurred within the framework" do
      it "says that the error occurred within the framework"
    end

    context "error occurred in the application" do
      it "says where the error occurred"
      it "includes the failing source"
    end
  end

  describe "#path" do
    context "error occurred within the framework" do
      it "returns an empty string"
    end

    context "error occurred in the application" do
      it "returns the path to where the error occurred"
    end
  end

  describe "#backtrace" do
    context "error occurred within the framework" do
      it "returns the full backtrace"
    end

    context "error occurred in the application" do
      it "returns the backtrace that concerns the application"
    end
  end
end
