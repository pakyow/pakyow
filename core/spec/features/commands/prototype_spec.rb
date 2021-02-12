require "pakyow/cli"

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
      cached_expectation "commands/prototype/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    before do
      expect(Pakyow).to receive(:run)
    end

    context "without any arguments" do
      it "boots with defaults" do
        run_command(command, project: true)
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
