require "pakyow/cli"

# TODO: rework this with the run work
RSpec.describe "cli: help" do
  include_context "command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  after do
    $helping = false
  end

  let :command do
    "help"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mGet help for the command line interface\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow help\n\n\e[1mARGUMENTS\e[0m\n  COMMAND  \e[33mThe command to get help for\e[0m\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "displays help for the cli" do
      expect(run_command(command)).to eq("\e[34;1mPakyow Command Line Interface\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow [COMMAND]\n\n\e[1mCOMMANDS\e[0m\n  boot            \e[33mBoot the environment\e[0m\n  help            \e[33mGet help for the command line interface\e[0m\n  info            \e[33mShow details about the current project\e[0m\n  info:endpoints  \e[33mShow defined endpoints for an app\e[0m\n  irb             \e[33mStart an interactive session\e[0m\n  prelaunch       \e[33mRun the prelaunch tasks\e[0m\n")
    end

    it "displays help for a command" do
      expect(run_command(command, "boot")).to eq("\e[34;1mBoot the environment\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow boot\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mWhat environment to use\e[0m\n      --host=host              \e[33mThe host the server runs on (default: localhost)\e[0m\n  -p, --port=port              \e[33mThe port the server runs on (default: 3000)\e[0m\n      --standalone             \e[33mDisable automatic reloading of changes\e[0m\n")
    end

    it "displays help for the help command" do
      expect(run_command(command, "help")).to eq("\e[34;1mGet help for the command line interface\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow help\n\n\e[1mARGUMENTS\e[0m\n  COMMAND  \e[33mThe command to get help for\e[0m\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end
end
