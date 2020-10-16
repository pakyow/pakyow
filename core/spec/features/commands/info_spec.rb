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
      expect(run_command(command, project: true)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})\n  Pakyow        v#{Pakyow::VERSION}\n\n\e[1mTestFoo::Application [:test_foo]\e[0m\n  Mount path    /\n  Frameworks    #{frameworks}\n  App root      #{File.expand_path("../../", command_dir) + "/core"}\n\n\e[1mTestBar::Application [:test_bar]\e[0m\n  Mount path    /bar\n  Frameworks    #{frameworks}\n  App root      #{File.expand_path("../../", command_dir) + "/core"}\n")
    end

    it "needs more specific tests"
  end
end
