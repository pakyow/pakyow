require "pakyow/cli"

RSpec.describe "cli: boot" do
  include_context "command"

  after do
    ENV.delete("APP_ENV")
    ENV.delete("RACK_ENV")
  end

  let :command do
    "boot"
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/boot/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    context "without any arguments" do
      it "boots with defaults" do
        expect(Pakyow).to receive(:run).with(env: :test, formation: Pakyow.config.runnable.formation)
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
        expect(Pakyow).to receive(:run).with(env: :test, formation: Pakyow.config.runnable.formation)
        run_command(command, host: "remotehost", port: "4242", project: true)

        expect(Pakyow.config.runnable.server.host).to eq("remotehost")
        expect(Pakyow.config.runnable.server.port).to eq("4242")
      end
    end

    context "running in standalone mode" do
      it "needs tests once restartability is added back"
    end

    describe "running a formation" do
      before do
        allow(Pakyow::Runnable::Formation).to receive(:parse).with(formation_string).and_return(formation)
      end

      let(:formation_string) {
        "environment.server=1"
      }

      let(:formation) {
        instance_double(Pakyow::Runnable::Formation)
      }

      it "runs with the parsed formation" do
        expect(Pakyow).to receive(:run).with(env: :test, formation: formation)

        run_command(command, formation: formation_string, project: true)
      end
    end

    describe "booting with specific mounts" do
      before do
        allow(Pakyow).to receive(:run)
      end

      it "sets the mounts option on the environment" do
        run_command(command, mounts: "foo,bar,baz", project: true)

        expect(Pakyow.config.mounts).to eq([:foo, :bar, :baz])
      end
    end
  end
end
