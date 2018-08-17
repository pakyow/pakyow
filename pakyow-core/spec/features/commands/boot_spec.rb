require "pakyow/cli"
require "pakyow/task"
require "pakyow/server"

RSpec.describe "cli: boot" do
  include_context "testable command"

  before do
    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  after do
    ENV.delete("APP_ENV")
    ENV.delete("RACK_ENV")
  end

  let :command do
    "boot"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mBoot the project server\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow boot\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mWhat environment to use\e[0m\n      --host=host              \e[33mThe host the server runs on (default: localhost)\e[0m\n  -p, --port=port              \e[33mThe port the server runs on (default: 3000)\e[0m\n      --standalone             \e[33mDisable automatic reloading of changes\e[0m\n")
    end
  end

  describe "running" do
    let :server_double do
      instance_double(Pakyow::Server, run: true)
    end

    context "without any arguments" do
      before do
        expect(server_double).to receive(:run)
      end

      it "boots with defaults" do
        expect(Pakyow::Server).to receive(:new).with(
          host: nil, port: nil, standalone: false
        ).and_return(server_double)

        run_command(command)
      end
    end

    context "passing a host and port" do
      before do
        expect(server_double).to receive(:run)
      end

      it "boots on the passed host and port" do
        expect(Pakyow::Server).to receive(:new).with(
          host: "remotehost", port: "4242", standalone: false
        ).and_return(server_double)

        run_command(command, "--host=remotehost", "--port=4242")
      end
    end

    context "running in standalone mode" do
      before do
        expect(server_double).to receive(:run)
      end

      it "boots in standalone mode" do
        expect(Pakyow::Server).to receive(:new).with(
          host: nil, port: nil, standalone: true
        ).and_return(server_double)

        run_command(command, "--standalone")
      end
    end

    context "running in production" do
      before do
        expect(server_double).to receive(:run)
      end

      it "defaults to standalone mode" do
        expect(Pakyow::Server).to receive(:new).with(
          host: nil, port: nil, standalone: true
        ).and_return(server_double)

        run_command(command, "--env=production")
      end
    end
  end
end
