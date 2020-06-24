require "pakyow/support/handleable"
require "pakyow/behavior/running/ensure_booted"

RSpec.describe Pakyow::Behavior::Running::EnsureBooted do
  subject { klass.new }

  let(:klass) {
    Class.new {
      include Pakyow::Support::Handleable
      include Pakyow::Behavior::Running::EnsureBooted

      def options
        {}
      end

      def handling
        yield
      rescue
      end
    }
  }

  describe "#ensure_booted" do
    context "environment is not booted" do
      it "yields" do
        expect { |block|
          subject.send(:ensure_booted, &block)
        }.to yield_control
      end

      it "deep freezes after yielding" do
        allow(Pakyow).to receive(:deep_freeze)

        subject.send(:ensure_booted) do
          expect(Pakyow).not_to have_received(:deep_freeze)
        end

        expect(Pakyow).to have_received(:deep_freeze)
      end

      context "environment fails to boot" do
        before do
          allow(Pakyow).to receive(:boot).and_raise(RuntimeError)
        end

        it "yields" do
          expect { |block|
          subject.send(:ensure_booted, &block)
        }.to yield_control
        end
      end
    end

    context "environment is booted" do
      before do
        allow(Pakyow).to receive(:booted?).and_return(true)
      end

      it "yields" do
        expect { |block|
          subject.send(:ensure_booted, &block)
        }.to yield_control
      end

      context "environment is rescued" do
        before do
          allow(Pakyow).to receive(:rescued?).and_return(true)
        end

        it "yields" do
          expect { |block|
          subject.send(:ensure_booted, &block)
        }.to yield_control
        end
      end
    end

    context "yield fails" do
      before do
        allow(Pakyow).to receive(:deep_freeze)

        begin
          subject.send(:ensure_booted) do
            fail "something went wrong"
          end
        rescue
        end
      end

      it "freezes the environment" do
        expect(Pakyow).to have_received(:deep_freeze)
      end
    end
  end
end
