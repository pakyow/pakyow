require "pakyow/cli"

RSpec.describe "cli: info" do
  include_context "command"

  before do
    Pakyow.app :foo
    Pakyow.app :bar, path: "/bar"

    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  after do
    Foo.constants(false).each do |const_to_unset|
      Foo.__send__(:remove_const, const_to_unset)
    end

    Bar.constants(false).each do |const_to_unset|
      Bar.__send__(:remove_const, const_to_unset)
    end

    Object.__send__(:remove_const, :Foo)
    Object.__send__(:remove_const, :Bar)
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
      expect(run_command(command)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})\n  Pakyow        v1.0.0.alpha1\n\n\e[1mFoo::App [:foo]\e[0m\n  Mount path    /\n  Frameworks    #{frameworks}\n  App root      #{command_dir}\n\n\e[1mBar::App [:bar]\e[0m\n  Mount path    /bar\n  Frameworks    #{frameworks}\n  App root      #{command_dir}\n")
    end

    it "needs more specific tests"
  end
end
