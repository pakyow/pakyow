RSpec.describe "running the environment" do
  before do
    allow(Pakyow).to receive(:start_processes).and_return(instance_double(Thread, join: nil))
  end

  after do
    if Pakyow.instance_variable_defined?(:@__process_thread)
      Pakyow.remove_instance_variable(:@__process_thread)
    end
  end

  describe "handling errors" do
    before do
      allow(Pakyow).to receive(:exit)
      allow(Pakyow.logger).to receive(:houston)
      allow(Async::Reactor).to receive(:run)
    end

    context "an application fails to run" do
      before do
        Pakyow.app :test_1 do
          on "setup" do
            fail
          end
        end

        Pakyow.app :test_2 do
        end
      end

      it "rescues the failed application" do
        Pakyow.run

        expect(Pakyow.app(:test_1).rescued?).to be(true)
      end

      it "continues running other applications" do
        expect(Pakyow.app(:test_2).rescued?).to be(false)
      end
    end

    context "some other error is encountered" do
      before do
        allow(Async::Reactor).to receive(:run) do
          raise error
        end
      end

      let(:error) {
        begin
          fail "something went wrong"
        rescue => error
          error
        end
      }

      it "exposes the error" do
        Pakyow.run

        expect(Pakyow.error).to be(error)
      end

      it "reports the error" do
        Pakyow.run

        expect(Pakyow.logger).to have_received(:houston).with(error)
      end

      context "exit_on_boot_failure is true" do
        before do
          Pakyow.config.exit_on_boot_failure = true
        end

        it "exits with the correct exit code" do
          Pakyow.run

          expect(Pakyow).to have_received(:exit).with(false)
        end
      end

      context "exit_on_boot_failure is false" do
        before do
          Pakyow.config.exit_on_boot_failure = false
        end

        it "does not exit" do
          Pakyow.run

          expect(Pakyow).not_to have_received(:exit)
        end
      end
    end
  end
end
