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
        expect(colorizer.colorize(message, Pakyow::Logger::NICE_LEVELS.key(:debug))).to eq "\e[36m#{message}\e[0m"
      end
    end

    context "when a color is not found for severity" do
      it "returns the original message" do
        expect(colorizer.colorize(message, "bar")).to eq message
      end
    end
  end

  describe ".color" do
    it "returns the color for verbose log level" do
      expect(colorizer.color(Pakyow::Logger::NICE_LEVELS.key(:verbose))).to eq(:magenta)
    end

    it "returns the color for debug log level" do
      expect(colorizer.color(Pakyow::Logger::NICE_LEVELS.key(:debug))).to eq(:cyan)
    end

    it "returns the color for info log level" do
      expect(colorizer.color(Pakyow::Logger::NICE_LEVELS.key(:info))).to eq(:green)
    end

    it "returns the color for warn log level" do
      expect(colorizer.color(Pakyow::Logger::NICE_LEVELS.key(:warn))).to eq(:yellow)
    end

    it "returns the color for error log level" do
      expect(colorizer.color(Pakyow::Logger::NICE_LEVELS.key(:error))).to eq(:red)
    end

    it "returns the color for fatal log level" do
      expect(colorizer.color(Pakyow::Logger::NICE_LEVELS.key(:fatal))).to eq(:red)
    end
  end
end
