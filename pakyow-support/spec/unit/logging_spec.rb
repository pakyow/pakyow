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
      before do
        if defined?(Pakyow.logger)
          class << Pakyow
            remove_method :logger
          end
        end
      end

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

  describe "::safe" do
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
          Pakyow::Support::Logging.safe(&block)
        }.to yield_with_args(logger)
      end
    end

    context "Pakyow.logger is not defined" do
      before do
        if defined?(Pakyow.logger)
          class << Pakyow
            remove_method :logger
          end
        end
      end

      let :logger do
        double(:logger)
      end

      it "yields an stdout logger" do
        expect(::Logger).to receive(:new).with($stdout).and_return(logger)

        expect { |block|
          Pakyow::Support::Logging.safe(&block)
        }.to yield_with_args(logger)
      end

      context "level is passed" do
        it "sets the level" do
          expect(::Logger).to receive(:new).with($stdout).and_return(logger)
          expect(logger).to receive(:level=).with(1)

          expect { |block|
            Pakyow::Support::Logging.safe(level: 1, &block)
          }.to yield_with_args(logger)
        end
      end

      context "formatter is passed" do
        it "sets the formatter" do
          expect(::Logger).to receive(:new).with($stdout).and_return(logger)
          expect(logger).to receive(:formatter=).with(:foo)

          expect { |block|
            Pakyow::Support::Logging.safe(formatter: :foo, &block)
          }.to yield_with_args(logger)
        end
      end
    end
  end
end
