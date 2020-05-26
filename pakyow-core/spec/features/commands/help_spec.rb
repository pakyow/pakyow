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
      cached_expectation "commands/help/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    it "displays help for the cli" do
      cached_expectation "commands/help/for/cli" do
        run_command(command, project: true)
      end
    end

    it "displays help for a command" do
      cached_expectation "commands/help/for/boot" do
        run_command(command, project: true)
      end
    end

    it "displays help for the help command" do
      cached_expectation "commands/help/for/help" do
        run_command(command, command: "help", project: true)
      end
    end
  end
end
