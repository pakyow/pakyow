require "pakyow/cli"

RSpec.describe "cli: projects:info" do
  include_context "testable command"

  before do
    Pakyow.app :foo
    Pakyow.app :bar, path: "/bar"

    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
    allow_any_instance_of(Pakyow::CLI).to receive(:load_environment)
    allow_any_instance_of(Pakyow::CLI).to receive(:configure_bootsnap)
  end

  after do
    Foo.__send__(:remove_const, :App)
    Bar.__send__(:remove_const, :App)
    Object.__send__(:remove_const, :Foo)
    Object.__send__(:remove_const, :Bar)
  end

  let :command do
    "projects:info"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mShow details about the current project\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow projects:info\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "shows project info" do
      expect(run_command(command)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v2.5.1-p57 (x86_64-darwin17)\n  Pakyow        v1.0.0.alpha1\n  Rack          v2.0.5\n\n\e[1mFoo::App [:foo]\e[0m\n  Mount path    /\n  Frameworks    []\n  App root      /Users/bryanp/src/pakyow/pakyow/spec/tmp\n\n\e[1mBar::App [:bar]\e[0m\n  Mount path    /\n  Frameworks    []\n  App root      /Users/bryanp/src/pakyow/pakyow/spec/tmp\n")
    end

    context "non-pakyow app is mounted" do
      class RackEndpoint
      end

      before do
        Pakyow.mount RackEndpoint, at: "/non-pakyow"
      end

      it "shows as much info as possible" do
        expect(run_command(command)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v2.5.1-p57 (x86_64-darwin17)\n  Pakyow        v1.0.0.alpha1\n  Rack          v2.0.5\n\n\e[1mFoo::App [:foo]\e[0m\n  Mount path    /\n  Frameworks    []\n  App root      /Users/bryanp/src/pakyow/pakyow/spec/tmp\n\n\e[1mBar::App [:bar]\e[0m\n  Mount path    /\n  Frameworks    []\n  App root      /Users/bryanp/src/pakyow/pakyow/spec/tmp\n\n\e[1mRackEndpoint\e[0m\n  Mount path    /\n")
      end
    end

    it "needs more specific tests"
  end
end
