require "pakyow/cli"
require "pakyow/task"

RSpec.describe "cli: prototype" do
  include_context "command"

  after do
    ENV.delete("APP_ENV")
    ENV.delete("RACK_ENV")
  end

  let :command do
    "prototype"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mBoot the prototype\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow prototype\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env    \e[33mThe environment to run this command under\e[0m\n      --host=host  \e[33mThe host the server runs on (default: localhost)\e[0m\n  -p, --port=port  \e[33mThe port the server runs on (default: 3000)\e[0m\n")
    end
  end

  describe "running" do
    before do
      expect(Pakyow).to receive(:run)
    end

    context "without any arguments" do
      it "boots with defaults" do
        run_command(command, project: true)

        Pakyow::Support::Deprecator.global.ignore do
          expect(Pakyow.config.server.proxy).to eq(true)
        end

        expect(Pakyow.config.runnable.server.host).to eq("localhost")
        expect(Pakyow.config.runnable.server.port).to eq(3000)
      end
    end

    context "passing a host and port" do
      it "boots on the passed host and port" do
        run_command(command, host: "remotehost", port: "4242", project: true)
        expect(Pakyow.config.runnable.server.host).to eq("remotehost")
        expect(Pakyow.config.runnable.server.port).to eq("4242")
      end
    end
  end
end
