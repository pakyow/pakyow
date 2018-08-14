require "pakyow/logger/colorizer"

RSpec.describe Pakyow::Logger::Colorizer do
  let :colorizer do
    Pakyow::Logger::Colorizer
  end

  describe ".colorize" do
    let :message do
      "foo"
    end

    context "when a color is found for severity" do
      it "returns the colorized message" do
        expect(colorizer.colorize(message, :debug)).to eq "\e[36m#{message}\e[0m"
      end
    end

    context "when a color is not found for severity" do
      it "returns the original message" do
        expect(colorizer.colorize(message, "bar")).to eq message
      end
    end
  end

  describe ".color" do
    it "returns the color for debug log level" do
      expect(colorizer.color(:debug))
    end

    it "returns the color for info log level" do
      expect(colorizer.color(:info))
    end

    it "returns the color for warn log level" do
      expect(colorizer.color(:warn))
    end

    it "returns the color for error log level" do
      expect(colorizer.color(:error))
    end

    it "returns the color for fatal log level" do
      expect(colorizer.color(:fatal))
    end
  end
end
