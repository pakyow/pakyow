require "pakyow/support/deprecator/reporters/null"

RSpec.describe Pakyow::Support::Deprecator::Reporters::Null do
  describe "::report" do
    it "does not yield" do
      expect { |block|
        described_class.report(&block)
      }.not_to yield_control
    end
  end
end
