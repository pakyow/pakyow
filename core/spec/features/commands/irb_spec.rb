require "irb"

require "pakyow/cli"
require "pakyow/task"

RSpec.describe "cli: irb" do
  include_context "command"

  let :command do
    "irb"
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/irb/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    it "starts irb" do
      expect(IRB).to receive(:start)
      run_command(command, project: true)
    end

    it "clears ARGV" do
      expect(IRB).to receive(:start)
      expect(ARGV).to receive(:clear).exactly(1).time.and_call_original
      run_command(command, project: true)
    end

    context "configured with pry" do
      before do
        Pakyow.config.cli.repl = Pry
      end

      it "uses pry instead of irb" do
        expect(Pry).to receive(:start)
        run_command(command, project: true)
      end
    end
  end
end
