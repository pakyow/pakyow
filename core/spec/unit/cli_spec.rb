require "pakyow/cli"

RSpec.describe Pakyow::CLI do
  let(:feedback) {
    double(:feedback).as_null_object
  }

  let(:output) {
    StringIO.new
  }

  describe "requiring config/environment.rb" do
    context "within the project folder" do
      before do
        allow(Pakyow).to receive(:project?).and_return(true)
      end

      it "loads the environment" do
        expect(Pakyow).to receive(:load)

        Pakyow::CLI.run([], output: output)
      end
    end

    context "outside of a project folder" do
      before do
        allow(Pakyow).to receive(:project?).and_return(false)
      end

      it "loads the environment" do
        expect(Pakyow).to receive(:load)

        Pakyow::CLI.run([], output: output)
      end
    end
  end

  describe "presenting commands based on context" do
    before do
      allow(Pakyow).to receive(:commands) do
        instance_double(Pakyow::Support::Definable::Registry).tap do |registry|
          allow(registry).to receive(:definitions).and_return(definitions)
        end
      end
    end

    let(:definitions) {
      [].tap do |commands|
        commands << Pakyow::Command.make(:test_1, description: "global", global: true)
        commands << Pakyow::Command.make(:test_2, description: "local", global: false)
      end
    }

    let :commands do
      Pakyow::CLI.new(feedback: feedback).send(:commands)
    end

    context "within the project folder" do
      before do
        allow(Pakyow).to receive(:project?).and_return(true)
      end

      it "only includes project commands" do
        expect(commands.length).to be(1)
        expect(commands[0].description).to eq("local")
      end
    end

    context "outside of a project folder" do
      before do
        allow(Pakyow).to receive(:project?).and_return(false)
      end

      it "only includes global commands" do
        expect(commands.length).to be(1)
        expect(commands[0].description).to eq("global")
      end
    end
  end

  describe "failing commands" do
    context "stdout is a tty" do
      before do
        allow(output).to receive(:tty?).and_return(true)
      end

      it "does not raise the error" do
        allow(Pakyow).to receive(:load).and_raise(RuntimeError)

        expect {
          Pakyow::CLI.run([], output: output)
        }.to_not raise_error
      end
    end

    context "stdout is not a tty" do
      before do
        allow(output).to receive(:tty?).and_return(false)
      end

      it "raises the error" do
        allow(Pakyow).to receive(:load).and_raise(RuntimeError)

        expect {
          Pakyow::CLI.run([], output: output)
        }.to raise_error(RuntimeError)
      end
    end
  end

  describe "exit codes" do
    context "stdout is a tty" do
      before do
        allow(output).to receive(:tty?).and_return(true)
      end

      context "command succeeds" do
        it "indicates success" do
          expect(::Process).not_to receive(:exit)
          Pakyow::CLI.run([], output: output)
        end
      end

      context "command fails" do
        before do
          allow(Pakyow).to receive(:load).and_raise(RuntimeError)
        end

        it "indicates failure" do
          expect(::Process).to receive(:exit).with(1)
          Pakyow::CLI.run([], output: output)
        end
      end
    end
  end
end
