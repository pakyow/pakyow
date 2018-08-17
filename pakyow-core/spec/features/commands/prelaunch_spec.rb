require "pakyow/cli"
require "pakyow/task"

RSpec.describe "cli: prelaunch" do
  include_context "testable command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  let :command do
    "prelaunch"
  end

  let :task do
    Pakyow.tasks.find { |task|
      task.name == "prelaunch"
    }
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mRun the prelaunch tasks\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow prelaunch\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    context "prelaunch tasks are defined for the environment" do
      it "runs each task with the defined options"
      it "adds the current env as an option"
      it "logs information about the task"
    end

    context "prelaunch tasks are defined for an app" do
      it "runs each task with the defined options"
      it "adds the current env as an option"
      it "adds the app as an option"
      it "logs information about the task"
    end

    context "prelaunch task does not exist" do
      it "errors"
    end

    context "prelaunch task errors" do
      it "errors"
      it "does not run other tasks"
    end
  end

end
