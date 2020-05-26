require "pakyow/cli"

RSpec.describe "cli: info" do
  include_context "command"

  before do
    Pakyow.app :test_foo
    Pakyow.app :test_bar, path: "/bar"
  end

  let :command do
    "info"
  end

  let :frameworks do
    Pakyow.frameworks.keys.inspect
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/info/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    it "shows project info" do
      cached_expectation "commands/info/project" do
        run_command(command, project: true)
      end
    end

    it "needs more specific tests"
  end
end
