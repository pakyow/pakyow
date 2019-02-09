require "pakyow/cli"
require "pakyow/task"

RSpec.describe "cli: irb" do
  include_context "command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  let :command do
    "irb"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mStart an interactive session\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow irb\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "starts irb" do
      expect(IRB).to receive(:start)
      run_command(command)
    end

    it "clears ARGV" do
      expect(IRB).to receive(:start)
      expect(ARGV).to receive(:clear).exactly(3).times.and_call_original
      run_command(command)
    end

    context "configured with pry" do
      before do
        Pakyow.config.cli.repl = Pry
      end

      it "uses pry instead of irb" do
        expect(Pry).to receive(:start)
        run_command(command)
      end
    end
  end
end
