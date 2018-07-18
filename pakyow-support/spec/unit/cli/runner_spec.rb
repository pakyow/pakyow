require "pakyow/support/cli/runner"

RSpec.describe Pakyow::Support::CLI::Runner do
  let :message do
    "testing"
  end

  let :instance do
    described_class.new(message: message)
  end

  describe "#initialize" do
    it "initializes with a message" do
      expect(instance).to be_instance_of(described_class)
    end

    it "initializes the spinner" do
      expect(TTY::Spinner).to receive(:new).with(
        "\e[1m:spinner testing\e[0m",
        format: :dots,
        success_mark: "✓",
        error_mark: "✕"
      )

      instance
    end

    it "has not completed" do
      expect(instance.completed?).to be(false)
    end

    it "has not succeeded" do
      expect(instance.succeeded?).to be(false)
    end

    it "has not failed" do
      expect(instance.failed?).to be(false)
    end
  end

  describe "#run" do
    context "passing a block" do
      it "starts the spinner" do
        expect_any_instance_of(TTY::Spinner).to receive(:auto_spin)

        capture_output do
          instance.run do; end
        end
      end

      it "yields self" do
        yielded_arg = nil
        capture_output do
          instance.run do |arg|
            yielded_arg = arg
          end
        end

        expect(yielded_arg).to be(instance)
      end

      it "succeeds" do
        capture_output do
          instance.run do; end
        end

        expect(instance.succeeded?).to be(true)
      end

      describe "output" do
        it "is formatted correctly" do
          output = capture_output do
            instance.run do
              puts "called"
            end
          end

          expect(output).to eq("\n" + "called\n" + "\n")
        end
      end
    end

    context "passing a command" do
      let :command do
        ["ls", "."]
      end

      it "starts the spinner" do
        expect_any_instance_of(TTY::Spinner).to receive(:auto_spin)

        capture_output do
          instance.run(command)
        end
      end

      it "runs the command" do
        expect_any_instance_of(TTY::Command).to receive(:run!).with(*command).and_return(
          double(TTY::Command::Result, failure?: false)
        )

        capture_output do
          instance.run(*command)
        end
      end

      describe "running the command" do
        it "runs as a pty without output" do
          expect(TTY::Command).to receive(:new).with(printer: :null, pty: true).and_return(
            double(TTY::Command, run!: double(TTY::Command::Result, failure?: false))
          )

          capture_output do
            instance.run(*command)
          end
        end
      end

      context "command succeeds" do
        before do
          expect_any_instance_of(TTY::Command).to receive(:run!).with(*command).and_return(
            result_double
          )
        end

        let :result_double do
          double(TTY::Command::Result, failure?: false)
        end

        it "calls succeeded" do
          expect(instance).to receive(:succeeded).with(no_args)

          capture_output do
            instance.run(*command)
          end
        end

        context "block was passed" do
          it "calls the block" do
            called = false
            called_with = nil
            capture_output do
              instance.run(*command) do |result|
                called = true
                called_with = result
              end
            end

            expect(called).to be(true)
            expect(called_with).to be(result_double)
          end
        end
      end

      context "command fails" do
        before do
          expect_any_instance_of(TTY::Command).to receive(:run!).with(*command).and_return(
            double(TTY::Command::Result, failure?: true, err: "command failed")
          )
        end

        it "calls failed" do
          expect(instance).to receive(:failed).with("command failed")

          capture_output do
            instance.run(*command)
          end
        end

        context "block was passed" do
          it "does not call the block" do
            called = false
            capture_output do
              instance.run(*command) do
                called = true
              end
            end

            expect(called).to be(false)
          end
        end
      end
    end
  end

  describe "#succeeded" do
    it "can be called" do
      expect { capture_output { instance.succeeded } }.not_to raise_error
    end

    it "says it has succeeded" do
      capture_output do
        instance.succeeded
      end

      expect(instance.succeeded?).to be(true)
    end

    it "says it has completed" do
      capture_output do
        instance.succeeded
      end

      expect(instance.completed?).to be(true)
    end

    it "stops the spinner" do
      expect_any_instance_of(TTY::Spinner).to receive(:success).with("")

      capture_output do
        instance.succeeded
      end
    end

    context "passing a message" do
      it "outputs the message" do
        output = capture_output do
          instance.succeeded("succeeded")
        end

        expect(output).to eq("   succeeded\n" + "\n")
      end
    end

    context "called again" do
      before do
        capture_output do
          instance.succeeded
        end
      end

      it "does not output" do
        output = capture_output do
          instance.succeeded("succeeded")
        end

        expect(output).to eq("")
      end
    end

    context "called after failed" do
      before do
        capture_output do
          instance.failed
        end
      end

      it "does not output" do
        output = capture_output do
          instance.succeeded("succeeded")
        end

        expect(output).to eq("")
      end

      it "does not say it has succeeded" do
        output = capture_output do
          instance.succeeded("succeeded")
        end

        expect(instance.succeeded?).to be(false)
      end

      it "does say it has failed" do
        output = capture_output do
          instance.failed("failed")
        end

        expect(instance.failed?).to be(true)
      end
    end
  end

  describe "#failed" do
    it "can be called" do
      expect { capture_output { instance.failed } }.not_to raise_error
    end

    it "says it has failed" do
      capture_output do
        instance.failed
      end

      expect(instance.failed?).to be(true)
    end

    it "says it has completed" do
      capture_output do
        instance.failed
      end

      expect(instance.completed?).to be(true)
    end

    it "stops the spinner" do
      expect_any_instance_of(TTY::Spinner).to receive(:error).with("\e[31mfailed\e[0m")

      capture_output do
        instance.failed
      end
    end

    context "passing a message" do
      it "outputs the message" do
        output = capture_output do
          instance.failed("failed")
        end

        expect(output).to eq("   failed\n" + "\n")
      end
    end

    context "called again" do
      before do
        capture_output do
          instance.failed
        end
      end

      it "does not output" do
        output = capture_output do
          instance.failed("failed")
        end

        expect(output).to eq("")
      end
    end

    context "called after succeeded" do
      before do
        capture_output do
          instance.succeeded
        end
      end

      it "does not output" do
        output = capture_output do
          instance.failed("failed")
        end

        expect(output).to eq("")
      end

      it "does not say it has failed" do
        output = capture_output do
          instance.failed("failed")
        end

        expect(instance.failed?).to be(false)
      end

      it "does say it has succeeded" do
        output = capture_output do
          instance.failed("failed")
        end

        expect(instance.succeeded?).to be(true)
      end
    end
  end
end
