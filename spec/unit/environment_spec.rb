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
        expect(Pakyow.config.tasks.paths).to eq(["./tasks", File.expand_path("../../../lib/pakyow/tasks", __FILE__)])
      end
    end

    describe "tasks.prelaunch" do
      it "has a default value" do
        expect(Pakyow.config.tasks.prelaunch).to eq([])
      end
    end

    describe "redis.connection.url" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.url).to eq("redis://127.0.0.1:6379")
      end

      context "REDIS_URL is set" do
        before do
          ENV["REDIS_URL"] = "worked"
        end

        after do
          ENV.delete("REDIS_URL")
        end

        it "uses REDIS_URL" do
          expect(Pakyow.config.redis.connection.url).to eq("worked")
        end
      end
    end

    describe "redis.connection.timeout" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.timeout).to eq(5.0)
      end
    end

    describe "redis.connection.driver" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.driver).to eq(nil)
      end
    end

    describe "redis.connection.id" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.id).to eq(nil)
      end
    end

    describe "redis.connection.tcp_keepalive" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.tcp_keepalive).to eq(0)
      end
    end

    describe "redis.connection.reconnect_attempts" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.reconnect_attempts).to eq(1)
      end
    end

    describe "redis.connection.inherit_socket" do
      it "has a default value" do
        expect(Pakyow.config.redis.connection.inherit_socket).to eq(false)
      end
    end

    describe "redis.key_prefix" do
      it "has a default value" do
        expect(Pakyow.config.redis.key_prefix).to eq("pw")
      end
    end

    describe "puma.host" do
      it "has a default value" do
        expect(Pakyow.config.puma.host).to eq(
          Pakyow.config.server.host
        )
      end

      context "HOST is set" do
        before do
          ENV["HOST"] = "foo"
        end

        after do
          ENV.delete("HOST")
        end

        it "defaults to HOST" do
          expect(Pakyow.config.puma.host).to eq("foo")
        end
      end
    end

    describe "puma.port" do
      it "has a default value" do
        expect(Pakyow.config.puma.port).to eq(
          Pakyow.config.server.port
        )
      end

      context "PORT is set" do
        before do
          ENV["PORT"] = "4242"
        end

        after do
          ENV.delete("PORT")
        end

        it "defaults to PORT" do
          expect(Pakyow.config.puma.port).to eq("4242")
        end
      end
    end

    describe "puma.binds" do
      it "has a default value" do
        expect(Pakyow.config.puma.binds).to eq([])
      end

      context "BIND is set" do
        before do
          ENV["BIND"] = "unix://"
        end

        after do
          ENV.delete("BIND")
        end

        it "includes BIND" do
          expect(Pakyow.config.puma.binds).to eq(["unix://"])
        end
      end
    end

    describe "puma.min_threads" do
      it "has a default value" do
        expect(Pakyow.config.puma.min_threads).to eq(5)
      end

      context "THREADS is set" do
        before do
          ENV["THREADS"] = "10"
        end

        after do
          ENV.delete("THREADS")
        end

        it "defaults to THREADS" do
          expect(Pakyow.config.puma.min_threads).to eq("10")
        end
      end
    end

    describe "puma.max_threads" do
      it "has a default value" do
        expect(Pakyow.config.puma.max_threads).to eq(5)
      end

      context "THREADS is set" do
        before do
          ENV["THREADS"] = "15"
        end

        after do
          ENV.delete("THREADS")
        end

        it "defaults to THREADS" do
          expect(Pakyow.config.puma.min_threads).to eq("15")
        end
      end
    end

    describe "puma.workers" do
      it "has a default value" do
        expect(Pakyow.config.puma.workers).to eq(5)
      end

      context "WORKERS is set" do
        before do
          ENV["WORKERS"] = "42"
        end

        after do
          ENV.delete("WORKERS")
        end

        it "defaults to WORKERS" do
          expect(Pakyow.config.puma.workers).to eq("42")
        end
      end
    end

    describe "puma.worker_timeout" do
      it "has a default value" do
        expect(Pakyow.config.puma.worker_timeout).to eq(60)
      end
    end

    describe "puma.on_restart" do
      it "has a default value" do
        expect(Pakyow.config.puma.on_restart).to eq([])
      end
    end

    describe "puma.before_fork" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_fork).to eq([])
      end
    end

    describe "puma.before_worker_boot" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_worker_fork.count).to be(1)

        expect(Pakyow).to receive(:forking)
        Pakyow.config.puma.before_worker_fork[0].call(nil)
      end
    end

    describe "puma.after_worker_fork" do
      it "has a default value" do
        expect(Pakyow.config.puma.after_worker_fork).to eq([])
      end
    end

    describe "puma.before_worker_boot" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_worker_boot.count).to be(1)

        expect(Pakyow).to receive(:forked)
        Pakyow.config.puma.before_worker_boot[0].call(nil)
      end
    end

    describe "puma.before_worker_shutdown" do
      it "has a default value" do
        expect(Pakyow.config.puma.before_worker_shutdown).to eq([])
      end
    end

    describe "puma.silent" do
      it "has a default value" do
        expect(Pakyow.config.puma.silent).to be(true)
      end

      context "in production" do
        before do
          Pakyow.configure!(:production)
        end

        it "has a default value" do
          expect(Pakyow.config.puma.silent).to be(false)
        end
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

    it "calls forking on each app" do
      app = double(:app)
      Pakyow.instance_variable_set(:@apps, [app])
      expect(app).to receive(:forking)
      Pakyow.forking
    end
  end

  describe ".forked" do
    it "calls after fork hooks, then calls booted" do
      expect(Pakyow).to receive(:call_hooks).with(:after, :fork)
      expect(Pakyow).to receive(:booted)
      Pakyow.forked
    end

    it "calls forked on each app" do
      app = double(:app)
      Pakyow.instance_variable_set(:@apps, [app])
      expect(app).to receive(:forked)
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
    before do
      allow(handler_double).to receive(:run).and_yield(server_double)
      allow(builder_double).to receive(:to_app)
      allow(Pakyow).to receive(:handler).and_return(handler_double)
      Pakyow.instance_variable_set(:@builder, builder_double)
    end

    let :handler_double do
      double(:handler)
    end

    let :builder_double do
      double(:builder)
    end

    let :server_double do
      double(:server)
    end

    context "called with a server" do
      it "exposes the server" do
        Pakyow.run(server: :foo)
        expect(Pakyow.server).to eq(:foo)
      end

      it "runs the passed server" do
        expect(Pakyow).to receive(:handler).with(:foo).and_return(handler_double)
        expect(Pakyow).to receive(:to_app).and_return(:app)
        expect(handler_double).to receive(:run) { |app, _| expect(app).to eq(:app) }
        Pakyow.run(server: :foo)
      end
    end

    context "called without a server" do
      it "exposes the default server" do
        Pakyow.run
        expect(Pakyow.server).to eq(Pakyow.config.server.name)
      end

      it "runs the default server" do
        expect(Pakyow).to receive(:handler).with(:puma).and_return(handler_double)
        expect(Pakyow).to receive(:to_app).and_return(:app)
        expect(handler_double).to receive(:run) { |app, _| expect(app).to eq(:app) }
        Pakyow.run
      end
    end

    context "called with a host" do
      it "sets the host" do
        Pakyow.run(host: "somehost")
        expect(Pakyow.host).to eq("somehost")
      end
    end

    context "called with a port" do
      it "sets the port" do
        Pakyow.run(port: 4242)
        expect(Pakyow.port).to eq(4242)
      end
    end

    context "called with a block" do
      it "yields" do
        Pakyow.run do
          @called = true
        end

        expect(@called).to be(true)
      end
    end

    describe "determining server options" do
      context "server config is defined" do
        it "passes the server options" do
          expect(handler_double).to receive(:run) { |_, options|
            expect(options[:workers]).to eq(Pakyow.config.puma.to_h[:workers])
          }

          Pakyow.run
        end

        it "remaps options for puma" do
          expect(handler_double).to receive(:run) { |_, options|
            expect(options[:Host]).to eq(Pakyow.config.puma.to_h[:host])
            expect(options[:Port]).to eq(Pakyow.config.puma.to_h[:port])
            expect(options[:Silent]).to eq(Pakyow.config.puma.to_h[:silent])
          }

          Pakyow.run
        end

        context "additional options are passed" do
          it "uses merged server config + passed options" do
            expect(handler_double).to receive(:run) { |_, options|
              expect(options[:workers]).to eq(Pakyow.config.puma.to_h[:workers])
              expect(options[:foo]).to eq(:bar)
            }

            Pakyow.run(foo: :bar)
          end

          it "gives precedence to passed options" do
            expect(handler_double).to receive(:run) { |_, options|
              expect(options[:workers]).to eq(42)
            }

            Pakyow.run(workers: 42)
          end
        end
      end

      context "server config is not defined" do
        it "does not pass any options" do
          expect(handler_double).to receive(:run) { |_, options|
            expect(options).to eq({})
          }

          Pakyow.run(server: :mock)
        end

        context "additional options are passed" do
          it "uses the passed options" do
            expect(handler_double).to receive(:run) { |_, options|
              expect(options).to eq(foo: :bar)
            }

            Pakyow.run(server: :mock, foo: :bar)
          end
        end
      end

      context "server config file exists" do
        before do
          expect(File).to receive(:exist?).with("./config/puma.rb").and_return(true)
        end

        it "passes no options" do
          expect(handler_double).to receive(:run) { |_, options|
            expect(options).to be_empty
          }

          Pakyow.run(foo: :bar)
        end
      end

      context "server config file exists for environment" do
        before do
          expect(File).to receive(:exist?).with("./config/puma.rb").and_return(false)
          expect(File).to receive(:exist?).with("./config/puma/fooenv.rb").and_return(true)
          Pakyow.instance_variable_set(:@env, "fooenv")
        end

        it "passes no options" do
          expect(handler_double).to receive(:run) { |_, options|
            expect(options).to be_empty
          }

          Pakyow.run(foo: :bar)
        end
      end
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

  describe "::find_app" do
    before do
      Pakyow.config.server.name = :mock

      Pakyow.app :foo, path: "/foo"
      Pakyow.app :bar, path: "/bar"
      Pakyow.app :baz, path: "/baz"
    end

    after do
        Foo.__send__(:remove_const, :App)
        Bar.__send__(:remove_const, :App)
        Baz.__send__(:remove_const, :App)
        Object.__send__(:remove_const, :Foo)
        Object.__send__(:remove_const, :Bar)
        Object.__send__(:remove_const, :Baz)
    end

    context "environment has booted" do
      before do
        Pakyow.setup(env: :test).run
      end

      it "returns an app instance" do
        expect(Pakyow.find_app(:foo).config.name).to eq(:foo)
        expect(Pakyow.find_app(:bar).config.name).to eq(:bar)
        expect(Pakyow.find_app(:baz).config.name).to eq(:baz)
      end
    end

    context "environment has not booted" do
      it "returns an app instance" do
        expect(Pakyow.find_app(:foo).config.name).to eq(:foo)
        expect(Pakyow.find_app(:bar).config.name).to eq(:bar)
        expect(Pakyow.find_app(:baz).config.name).to eq(:baz)
      end
    end
  end
end
