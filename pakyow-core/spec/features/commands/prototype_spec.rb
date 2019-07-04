require "pakyow/cli"
require "pakyow/task"

RSpec.describe "cli: prototype" do
  include_context "command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  after do
    ENV.delete("APP_ENV")
    ENV.delete("RACK_ENV")
  end

  let :command do
    "prototype"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mBoot the prototype\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow prototype\n\n\e[1mOPTIONS\e[0m\n      --host=host  \e[33mThe host the server runs on (default: localhost)\e[0m\n  -p, --port=port  \e[33mThe port the server runs on (default: 3000)\e[0m\n")
    end
  end

  describe "mode" do
    before do
      expect(Pakyow).to receive(:run)
    end

    it "boots into prototype mode" do
      expect(Pakyow).to receive(:setup) do |env:|
        expect(env).to eq(:prototype)
      end

      run_command(command)
    end
  end

  describe "running" do
    before do
      expect(Pakyow).to receive(:run)
    end

    context "without any arguments" do
      it "boots with defaults" do
        run_command(command)
        expect(Pakyow.config.server.proxy).to eq(true)
        expect(Pakyow.config.server.host).to eq("localhost")
        expect(Pakyow.config.server.port).to eq(3000)
      end
    end

    context "passing a host and port" do
      it "boots on the passed host and port" do
        run_command(command, "--host=remotehost", "--port=4242")
        expect(Pakyow.config.server.host).to eq("remotehost")
        expect(Pakyow.config.server.port).to eq("4242")
      end
    end
  end
end
