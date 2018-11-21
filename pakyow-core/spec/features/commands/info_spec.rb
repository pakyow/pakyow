require "pakyow/cli"

RSpec.describe "cli: info" do
  include_context "testable command"

  before do
    Pakyow.app :foo
    Pakyow.app :bar, path: "/bar"

    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)

  end

  after do
    Foo.__send__(:remove_const, :App)
    Bar.__send__(:remove_const, :App)
    Object.__send__(:remove_const, :Foo)
    Object.__send__(:remove_const, :Bar)
  end

  let :command do
    "info"
  end

  let :frameworks do
    Pakyow.frameworks.keys.inspect
  end

  let :local_path do
    File.expand_path("../../../../../", __FILE__)
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mShow details about the current project\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow info\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "shows project info" do
      expect(run_command(command)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})\n  Pakyow        v1.0.0.alpha1\n  Rack          v2.0.6\n\n\e[1mFoo::App [:foo]\e[0m\n  Mount path    /\n  Frameworks    #{frameworks}\n  App root      #{local_path}/spec/tmp\n\n\e[1mBar::App [:bar]\e[0m\n  Mount path    /bar\n  Frameworks    #{frameworks}\n  App root      #{local_path}/spec/tmp\n")
    end

    context "non-pakyow app is mounted" do
      class RackEndpoint
      end

      before do
        Pakyow.mount RackEndpoint, at: "/non-pakyow"
      end

      it "shows as much info as possible" do
        expect(run_command(command)).to eq("\e[1mLIBRARY VERSIONS\e[0m\n  Ruby          v#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL} (#{RUBY_PLATFORM})\n  Pakyow        v1.0.0.alpha1\n  Rack          v2.0.6\n\n\e[1mFoo::App [:foo]\e[0m\n  Mount path    /\n  Frameworks    #{frameworks}\n  App root      #{local_path}/spec/tmp\n\n\e[1mBar::App [:bar]\e[0m\n  Mount path    /bar\n  Frameworks    #{frameworks}\n  App root      #{local_path}/spec/tmp\n\n\e[1mRackEndpoint\e[0m\n  Mount path    /non-pakyow\n")
      end
    end

    it "needs more specific tests"
  end
end
