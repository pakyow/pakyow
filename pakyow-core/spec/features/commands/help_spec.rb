require "pakyow/cli"

RSpec.describe "cli: help" do
  include_context "command"

  after do
    $helping = false
  end

  let :command do
    "help"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mGet help for the command line interface\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow help\n\n\e[1mARGUMENTS\e[0m\n  COMMAND  \e[33mThe command to get help for\e[0m\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mThe environment to run this command under\e[0m\n")
    end
  end

  describe "running" do
    it "displays help for the cli" do
      expect(run_command(command, project: true)).to eq("\e[34;1mPakyow Command Line Interface\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow [COMMAND]\n\n\e[1mCOMMANDS\e[0m\n  boot               \e[33mBoot the project\e[0m\n  help               \e[33mGet help for the command line interface\e[0m\n  info               \e[33mShow details about the current project\e[0m\n  info:endpoints     \e[33mShow defined endpoints for an app\e[0m\n  irb                \e[33mStart an interactive session\e[0m\n  prelaunch          \e[33mRun all phases of the prelaunch sequence\e[0m\n  prelaunch:build    \e[33mRun the build phase of the prelaunch sequence\e[0m\n  prelaunch:release  \e[33mRun the release phase of the prelaunch sequence\e[0m\n  prototype          \e[33mBoot the prototype\e[0m\n")
    end

    it "displays help for a command" do
      expect(run_command(command, command: "boot", project: true)).to eq("\e[34;1mBoot the project\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow boot\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mThe environment to run this command under\e[0m\n      --host=host              \e[33mThe host the server runs on (default: localhost)\e[0m\n  -p, --port=port              \e[33mThe port the server runs on (default: 3000)\e[0m\n      --standalone             \e[33mDisable automatic reloading of changes\e[0m\n")
    end

    it "displays help for the help command" do
      expect(run_command(command, command: "help", project: true)).to eq("\e[34;1mGet help for the command line interface\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow help\n\n\e[1mARGUMENTS\e[0m\n  COMMAND  \e[33mThe command to get help for\e[0m\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mThe environment to run this command under\e[0m\n")
    end
  end
end
