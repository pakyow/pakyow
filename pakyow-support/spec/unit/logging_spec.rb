require "pakyow/support/logging"

RSpec.describe Pakyow::Support::Logging do
  describe "::yield_or_raise" do
    let :error do
      RuntimeError.new
    end

    context "Pakyow.logger is defined" do
      before do
        Pakyow.class_eval do
          def self.logger
          end
        end

        allow(Pakyow).to receive(:logger).and_return(logger)
      end

      after do
        class << Pakyow
          remove_method :logger
        end
      end

      let :logger do
        double(:logger)
      end

      it "yields the logger" do
        expect { |block|
          Pakyow::Support::Logging.yield_or_raise(error, &block)
        }.to yield_with_args(logger)
      end

      it "does not raise the error" do
        expect {
          Pakyow::Support::Logging.yield_or_raise(error) {}
        }.not_to raise_error
      end
    end

    context "Pakyow.logger is not defined" do
      it "raises the error" do
        expect {
          Pakyow::Support::Logging.yield_or_raise(error) {}
        }.to raise_error(error)
      end

      it "does not yield" do
        expect { |block|
          begin
            Pakyow::Support::Logging.yield_or_raise(error, &block)
          rescue
          end
        }.not_to yield_control
      end
    end
  end
end
