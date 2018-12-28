require_relative "environment/shared_examples/booted"

RSpec.describe Pakyow do
  describe "::register_framework" do
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

  describe "::mount" do
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

  describe "::fork" do
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

  describe "::forking" do
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

  describe "::forked" do
    after do
      Pakyow.forked
    end

    it "calls after fork hooks, then calls booted" do
      expect(Pakyow).to receive(:call_hooks).with(:after, :fork)
      expect(Pakyow).to receive(:booted)
    end

    it "calls forked on each app" do
      app = double(:app)
      Pakyow.instance_variable_set(:@apps, [app])
      expect(app).to receive(:forked)
    end

    include_examples :environment_booted
  end

  describe "::load" do
    before do
      allow(Pakyow).to receive(:load).and_call_original
      allow(Pakyow).to receive(:require)
    end

    it "performs the load event" do
      expect(Pakyow).to receive(:performing).with(:load)
      Pakyow.load
    end

    context "environment loader does not exist" do
      describe "bundler setup" do
        before do
          allow(Pakyow).to receive(:require).with("pakyow/integrations/bundler/setup") do
            load "pakyow/integrations/bundler/setup.rb"
          end
        end

        context "bundler is available" do
          before do
            expect(defined?(Bundler)).to eq("constant")
          end

          it "sets up bundler" do
            expect(TOPLEVEL_BINDING.receiver).to receive(:require).with("bundler/setup")
            Pakyow.load
          end
        end

        context "bundler is not available" do
          before do
            @const = Bundler
            Object.send(:remove_const, :Bundler)
          end

          after do
            Object.const_set(:Bundler, @const)
          end

          it "does not setup bundler" do
            expect(TOPLEVEL_BINDING.receiver).to_not receive(:require).with("bundler/setup")
            Pakyow.load
          end
        end
      end

      describe "bootsnap setup" do
        before do
          allow(Pakyow).to receive(:require).with("pakyow/integrations/bootsnap") do
            load "pakyow/integrations/bootsnap.rb"
          end

          require "bootsnap"
        end

        let :cache_dir do
          File.join(Dir.pwd, "tmp/cache")
        end

        context "bootsnap is available" do
          before do
            expect(TOPLEVEL_BINDING.receiver).to receive(:require).with("bootsnap").and_call_original
          end

          context "environment is development" do
            before do
              allow(Pakyow).to receive(:env?).with(:development).and_return(true)
            end

            it "sets up bootsnap in development mode" do
              expect(Bootsnap).to receive(:setup).with({
                cache_dir:            cache_dir,
                development_mode:     true,
                load_path_cache:      true,
                autoload_paths_cache: false,
                disable_trace:        false,
                compile_cache_iseq:   true,
                compile_cache_yaml:   true
              })

              Pakyow.load
            end
          end

          context "environment is not development" do
            before do
              allow(Pakyow).to receive(:env?).with(:development).and_return(false)
            end

            it "sets up bootsnap, but not in development mode" do
              expect(Bootsnap).to receive(:setup).with({
                cache_dir:            cache_dir,
                development_mode:     false,
                load_path_cache:      true,
                autoload_paths_cache: false,
                disable_trace:        false,
                compile_cache_iseq:   true,
                compile_cache_yaml:   true
              })

              Pakyow.load
            end
          end
        end

        context "bootsnap is not available" do
          before do
            expect(TOPLEVEL_BINDING.receiver).to receive(:require).with("bootsnap").and_raise(LoadError)
          end

          it "does not setup bootsnap" do
            expect(Bootsnap).to_not receive(:setup)
            Pakyow.load
          end
        end
      end

      describe "bundler require" do
        before do
          allow(Pakyow).to receive(:require).with("pakyow/integrations/bundler/require") do
            load "pakyow/integrations/bundler/require.rb"
          end
        end

        context "bundler is available" do
          before do
            expect(defined?(Bundler)).to eq("constant")
          end

          it "requires the bundle" do
            expect(Bundler).to receive(:require).with(:default, Pakyow.env)
            Pakyow.load
          end
        end

        context "bundler is not available" do
          before do
            @const = Bundler
            Object.send(:remove_const, :Bundler)
          end

          after do
            Object.const_set(:Bundler, @const)
          end

          it "does not require the bundle" do
            expect {
              Pakyow.load
            }.not_to raise_error
          end
        end
      end

      describe "dotenv setup" do
        before do
          allow(Pakyow).to receive(:require).with("pakyow/integrations/dotenv") do
            load "pakyow/integrations/dotenv.rb"
          end

          require "dotenv"
        end

        context "dotenv is available" do
          before do
            expect(defined?(Dotenv)).to eq("constant")
          end

          it "loads dotenv" do
            expect(Dotenv).to receive(:load)
            Pakyow.load
          end

          context "environment-specific dotfile is available" do
            before do
              Pakyow.instance_variable_set(:@env, :test)

              allow(Dotenv).to receive(:load)
              allow(File).to receive(:exist?)
              allow(File).to receive(:exist?).with(".env.test").and_return(true)
            end

            it "loads the environment-specific dotfile" do
              expect(Dotenv).to receive(:load).with(".env.test")
              Pakyow.load
            end

            it "loads dotenv" do
              expect(Dotenv).to receive(:load).with(no_args)
              Pakyow.load
            end
          end
        end

        context "dotenv is not available" do
          before do
            @const = Dotenv
            Object.send(:remove_const, :Dotenv)
          end

          after do
            Object.const_set(:Dotenv, @const)
          end

          it "does not load dotenv" do
            expect {
              Pakyow.load
            }.not_to raise_error
          end
        end
      end

      it "requires the environment" do
        expect(Pakyow).to receive(:require).with(Pakyow.config.environment_path)
        Pakyow.load
      end

      it "calls load_apps" do
        expect(Pakyow).to receive(:load_apps)
        Pakyow.load
      end
    end

    context "environment loader exists" do
      before do
        allow(File).to receive(:exist?).with(Pakyow.config.loader_path + ".rb").and_return(true)
      end

      it "requires the loader" do
        expect(Pakyow).to receive(:require).with(Pakyow.config.loader_path)
        Pakyow.load
      end

      it "does not setup bundler" do
        expect(Pakyow).to_not receive(:require).with("pakyow/integrations/bundler/setup")
        Pakyow.load
      end

      it "does not setup bootsnap" do
        expect(Pakyow).to_not receive(:require).with("pakyow/integrations/bootsnap")
        Pakyow.load
      end

      it "does not require the bundle" do
        expect(Pakyow).to_not receive(:require).with("pakyow/integrations/bundler/require")
        Pakyow.load
      end

      it "does not setup dotenv" do
        expect(Pakyow).to_not receive(:require).with("pakyow/integrations/dotenv")
        Pakyow.load
      end

      it "does not require the environment" do
        expect(Pakyow).to_not receive(:require).with(Pakyow.config.environment_path)
        Pakyow.load
      end

      it "does not call load_apps" do
        expect(Pakyow).to_not receive(:load_apps)
        Pakyow.load
      end
    end
  end

  describe "::load_apps" do
    after do
      Pakyow.load_apps
    end

    it "requires the application" do
      expect(Pakyow).to receive(:require).with("./config/application")
    end
  end

  describe "::setup" do
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

    it "loads the environment" do
      expect(Pakyow).to receive(:load)
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

  describe "::boot" do
    after do
      Pakyow.boot
    end

    include_examples :environment_booted
  end

  describe "::run" do
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

    describe "handling exits" do
      it "registers an at_exit handler" do
        expect(Pakyow).to receive(:at_exit)
        Pakyow.run
      end

      it "registers a trap for each signal" do
        expect(Pakyow).to receive(:trap).with("INT")
        expect(Pakyow).to receive(:trap).with("TERM")
        Pakyow.run
      end

      describe "at_exit handler" do
        it "calls stop with the server" do
          expect(Pakyow).to receive(:at_exit) do |&block|
            expect(Pakyow).to receive(:stop).with(server_double)
            block.call
          end

          Pakyow.run
        end
      end

      describe "signal trap" do
        it "calls stop with the server" do
          expect(Pakyow).to receive(:trap).with("INT") do |&block|
            expect(Pakyow).to receive(:stop).with(server_double)
            block.call
          end

          expect(Pakyow).to receive(:trap).with("TERM") do |&block|
            expect(Pakyow).to receive(:stop).with(server_double)
            block.call
          end

          Pakyow.run
        end
      end
    end
  end

  describe "::to_app" do
    before do
      allow(Pakyow.builder).to receive(:to_app).and_return(double(:builder))
    end

    after do
      Pakyow.to_app
    end

    include_examples :environment_booted
  end

  describe "::apps" do
    include_context "app"

    let :app do
      Class.new
    end

    it "contains mounted app instances after boot" do
      expect(Pakyow.apps).to include(app)
    end
  end

  describe "::env?" do
    before do
      Pakyow.setup(env: :test)
    end

    it "returns true when the environment matches" do
      expect(Pakyow.env?(:test)).to be(true)
    end

    it "returns false when the environment does not match" do
      expect(Pakyow.env?(:toast)).to be(false)
    end
  end

  describe "::app" do
    before do
      Pakyow.app :foo, path: "/foo"
      Pakyow.app :bar, path: "/bar"
      Pakyow.app :baz, path: "/baz"

      Pakyow.boot
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
        Pakyow.setup(env: :test).boot
      end

      it "returns an app instance" do
        expect(Pakyow.app(:foo).config.name).to eq(:foo)
        expect(Pakyow.app(:bar).config.name).to eq(:bar)
        expect(Pakyow.app(:baz).config.name).to eq(:baz)
      end
    end
  end

  describe "::stop" do
    let :server_double do
      double(:server)
    end

    let :app_double do
      double(:app)
    end

    before do
      Pakyow.apps << app_double
    end

    it "calls before shutdown hooks" do
      expect(Pakyow).to receive(:call_hooks).with(:before, :shutdown)
      Pakyow.send(:stop, server_double)
    end

    it "calls shutdown on each registered app" do
      expect(app_double).to receive(:shutdown)
      Pakyow.send(:stop, server_double)
    end

    it "tries to shutdown the server gracefully with stop!" do
      expect(server_double).to receive(:stop!)
      Pakyow.send(:stop, server_double)
    end

    it "tries to shutdown the server gracefully with stop" do
      expect(server_double).to receive(:stop)
      Pakyow.send(:stop, server_double)
    end

    context "registered app does not implement shutdown" do
      before do
        Pakyow.apps << app_double
      end

      it "does not attempt to call shutdown on the app" do
        expect {
          Pakyow.send(:stop, server_double)
        }.not_to raise_error
      end
    end

    context "server shuts down gracefully" do
      before do
        expect(server_double).to receive(:stop!)
      end

      it "does not exit the process" do
        expect(Process).not_to receive(:exit!)
        Pakyow.send(:stop, server_double)
      end
    end

    context "server cannot shutdown gracefully" do
      it "exits the process" do
        expect(Process).to receive(:exit!)
        Pakyow.send(:stop, server_double)
      end
    end
  end
end
