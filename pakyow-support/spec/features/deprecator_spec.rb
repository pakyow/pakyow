require "pakyow/support/deprecator"

RSpec.describe "using a deprecator" do
  let(:instance) {
    Pakyow::Support::Deprecator.new(
      reporter: reporter
    )
  }

  context "with the log reporter" do
    require "pakyow/support/deprecator/reporters/log"

    let(:reporter) {
      Pakyow::Support::Deprecator::Reporters::Log.new(
        logger: logger
      )
    }

    let(:logger) {
      double("logger")
    }

    it "warns by default" do
      expect(logger).to receive(:warn) do |&block|
        expect(block.call).to eq("[deprecation] `foo' is deprecated; solution: use `bar'")
      end

      instance.deprecated :foo, solution: "use `bar'"
    end

    context "with an explicit level" do
      let(:reporter) {
        Pakyow::Support::Deprecator::Reporters::Log.new(
          logger: logger, level: :debug
        )
      }

      it "logs with the level" do
        expect(logger).to receive(:debug)

        instance.deprecated :foo, solution: "use `bar'"
      end
    end
  end
end
