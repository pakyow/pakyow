require "pakyow/cli"

RSpec.describe "cli: info" do
  include_context "command"

  before do
    Pakyow.app :test_foo
    Pakyow.app :test_bar, path: "/bar"

    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  let :command do
    "info"
  end

  let :frameworks do
    Pakyow.frameworks.keys.inspect
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mShow details about the current project\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow info\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "shows project info" do
      expect(run_command(command)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})\n  Pakyow        v#{Pakyow::VERSION}\n\n\e[1mTestFoo::App [:test_foo]\e[0m\n  Mount path    /\n  Frameworks    #{frameworks}\n  App root      #{File.expand_path("../../", command_dir) + "/pakyow-core"}\n\n\e[1mTestBar::App [:test_bar]\e[0m\n  Mount path    /bar\n  Frameworks    #{frameworks}\n  App root      #{File.expand_path("../../", command_dir) + "/pakyow-core"}\n")
    end

    it "needs more specific tests"
  end
end
