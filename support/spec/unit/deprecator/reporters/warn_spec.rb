require "pakyow/support/deprecator/reporters/warn"

RSpec.describe Pakyow::Support::Deprecator::Reporters::Warn do
  describe "::report" do
    it "warns" do
      expect(described_class).to receive(:warn).with("[deprecation] message")

      described_class.report {
        "message"
      }
    end
  end
end
