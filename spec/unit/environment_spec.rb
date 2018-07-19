RSpec.describe Pakyow do
  describe "known events" do
    it "includes `configure`" do
      expect(Pakyow.known_events).to include(:configure)
    end

    it "includes `setup`" do
      expect(Pakyow.known_events).to include(:setup)
    end

    it "includes `fork`" do
      expect(Pakyow.known_events).to include(:fork)
    end

    it "includes `boot`" do
      expect(Pakyow.known_events).to include(:boot)
    end
  end

  describe "configuration options" do
    describe "default_env" do
      it "has a default value" do
        expect(Pakyow.config.default_env).to eq(:development)
      end
    end

    describe "server.name" do
      it "has a default value" do
        expect(Pakyow.config.server.name).to eq(:puma)
      end
    end

    describe "server.port" do
      it "has a default value" do
        expect(Pakyow.config.server.port).to eq(3000)
      end
    end

    describe "server.host" do
      it "has a default value" do
        expect(Pakyow.config.server.host).to eq("localhost")
      end
    end

    describe "cli.repl" do
      it "has a default value" do
        expect(Pakyow.config.cli.repl).to eq(IRB)
      end
    end

    describe "logger.enabled" do
      it "has a default value" do
        expect(Pakyow.config.logger.enabled).to eq(true)
      end

      context "in test" do
        before do
          Pakyow.configure!(:test)
        end

        it "defaults to false" do
          expect(Pakyow.config.logger.enabled).to eq(false)
        end
      end

      context "in ludicrous" do
        before do
          Pakyow.configure!(:ludicrous)
        end

        it "defaults to false" do
          expect(Pakyow.config.logger.enabled).to eq(false)
        end
      end
    end

    describe "logger.level" do
      it "has a default value" do
        expect(Pakyow.config.logger.level).to eq(:debug)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to info" do
          expect(Pakyow.config.logger.level).to eq(:info)
        end
      end
    end

    describe "logger.formatter" do
      it "has a default value" do
        expect(Pakyow.config.logger.formatter).to eq(Pakyow::Logger::DevFormatter)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "defaults to logfmt" do
          expect(Pakyow.config.logger.formatter).to eq(Pakyow::Logger::LogfmtFormatter)
        end
      end
    end

    describe "logger.destinations" do
      context "when logger is enabled" do
        before do
          Pakyow.config.logger.enabled = true
        end

        it "defaults to stdout" do
          expect(Pakyow.config.logger.destinations).to eq([$stdout])
        end
      end

      context "when logger is disabled" do
        before do
          Pakyow.config.logger.enabled = false
        end

        it "defaults to /dev/null" do
          expect(Pakyow.config.logger.destinations).to eq(["/dev/null"])
        end
      end
    end

    describe "normalizer.strict_path" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_path).to eq(true)
      end
    end

    describe "normalizer.strict_www" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.strict_www).to eq(false)
      end
    end

    describe "normalizer.require_www" do
      it "has a default value" do
        expect(Pakyow.config.normalizer.require_www).to eq(true)
      end
    end

    describe "tasks.paths" do
      it "has a default value" do
        expect(Pakyow.config.tasks.paths).to eq(["./tasks"])
      end
    end
  end

  describe ".mount" do
    let :app do
      Class.new
    end

    let :path do
      ""
    end

    context "called with an app and path" do
      before do
        Pakyow.mount app, at: path
      end

      it "registers the app" do
        expect(Pakyow.instance_variable_get(:@mounts)[path][:app]).to be(app)
      end

      context "and passed a block" do
        let :block do
          -> {}
        end

        before do
          Pakyow.mount app, at: path, &block
        end

        it "registers the block" do
          expect(Pakyow.instance_variable_get(:@mounts)[path][:block]).to be(block)
        end
      end
    end

    context "called without an app" do
      it "raises an error" do
        expect {
          Pakyow.mount at: path
        }.to raise_error(ArgumentError)
      end
    end

    context "called without a path" do
      it "raises an error" do
        expect {
          Pakyow.mount app
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".fork" do
    it "calls `forking`" do
      expect(Pakyow).to receive(:forking)
      Pakyow.fork {}
    end

    it "calls `forked`" do
      expect(Pakyow).to receive(:forked)
      Pakyow.fork {}
    end

    it "yields" do
      @called = false
      Pakyow.fork {
        @called = true
      }

      expect(@called).to be(true)
    end
  end

  describe ".forking" do
    it "calls before fork hooks" do
      expect(Pakyow).to receive(:call_hooks).with(:before, :fork)
      Pakyow.forking
    end
  end

  describe ".forked" do
    it "calls after fork hooks" do
      expect(Pakyow).to receive(:call_hooks).with(:after, :fork)
      Pakyow.forked
    end
  end

  describe ".call" do
    let :env do
      { foo: :bar }
    end

    it "calls the builder" do
      expect_any_instance_of(Rack::Builder).to receive(:call).with(env)
      Pakyow.call(env)
    end
  end

  describe ".setup" do
    context "called with an environment name" do
      let :name do
        :foo
      end

      before do
        Pakyow.setup(env: name)
      end

      it "uses the passed name" do
        expect(Pakyow.env).to be(name)
      end
    end

    context "called without an environment name" do
      before do
        Pakyow.setup
      end

      it "uses the default name" do
        expect(Pakyow.env).to be(Pakyow.config.default_env)
      end
    end

    it "calls hooks" do
      expect(Pakyow).to receive(:performing).with(:configure)
      expect(Pakyow).to receive(:performing).with(:setup)
      Pakyow.setup
    end

    it "configures for the environment" do
      env = :foo
      expect(Pakyow).to receive(:configure!).with(env)
      Pakyow.setup(env: env)
    end

    it "initializes the logger" do
      expect(Pakyow.logger).to be_nil
      Pakyow.setup

      expect(Pakyow.logger).to be_instance_of(Logger)
    end

    it "returns the environment" do
      expect(Pakyow.setup).to be(Pakyow)
    end
  end

  describe ".register_framework" do
    it "registers a framework by name and module" do
      class FooFramework
        def initialize(_); end
        def boot; end
      end

      Pakyow.register_framework(:foo, FooFramework)
      expect(Pakyow.frameworks.keys).to include(:foo)
      expect(Pakyow.frameworks.values).to include(FooFramework)

      Object.send(:remove_const, :FooFramework)
    end
  end

  describe ".run" do
    def run(opts = { port: port, host: host, server: server })
      allow(Pakyow).to receive(:handler).and_return(handler_double)
      Pakyow.instance_variable_set(:@builder, builder_double)
      Pakyow.run(**opts)
    end

    let :handler_double do
      double.as_null_object
    end

    let :builder_double do
      double.as_null_object
    end

    let :port do
      4242
    end

    let :host do
      "local.dev"
    end

    let :server do
      :mock
    end

    context "called with a port" do
      before do
        run
      end

      it "uses the passed port" do
        expect(Pakyow.port).to be(port)
      end
    end

    context "called without a port" do
      let :port do
        nil
      end

      before do
        run
      end

      it "uses the default port" do
        expect(Pakyow.port).to be(Pakyow.config.server.port)
      end
    end

    context "called with a host" do
      before do
        run
      end

      it "uses the passed host" do
        expect(Pakyow.host).to be(host)
      end
    end

    context "called without a host" do
      let :host do
        nil
      end

      before do
        run
      end

      it "uses the default host" do
        expect(Pakyow.host).to be(Pakyow.config.server.host)
      end
    end

    context "called with a server" do
      before do
        run
      end

      it "uses the passed server" do
        expect(Pakyow.server).to be(server)
      end
    end

    context "called without a server" do
      let :server do
        nil
      end

      before do
        run
      end

      it "uses the default server" do
        expect(Pakyow.server).to be(Pakyow.config.server.name)
      end
    end

    context "called with extra opts" do
      before do
        run(port: port, host: host, foo: :bar)
      end

      it "passes on the default opts" do
        expect(handler_double).to have_received(:run).with(builder_double, Host: host, Port: port, Silent: true, foo: :bar)
      end
    end

    it "looks up the handler for the server" do
      run
      expect(Pakyow).to have_received(:handler).with(server)
    end

    it "runs the handler with the builder on the right host / port" do
      run
      expect(handler_double).to have_received(:run).with(builder_double, Host: host, Port: port)
    end

    it "calls booted on each app" do
      app = double(:app)
      Pakyow.instance_variable_set(:@apps, [app])
      expect(app).to receive(:booted)
      run
    end
  end

  describe "#apps" do
    let :app do
      Class.new
    end

    let :app_runtime_block do
      -> {}
    end

    before do
      Pakyow.config.server.name = :mock
    end

    it "contains mounted app instances after boot" do
      run
      expect(Pakyow.instance_variable_get(:@apps)).to include(app)
    end
  end

  describe "#env?" do
    it "returns true when the environment matches"
    it "returns false when the environment does not match"
  end
end
