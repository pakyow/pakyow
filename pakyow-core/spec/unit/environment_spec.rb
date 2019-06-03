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

      it "registers the app at the path" do
        expect(Pakyow.mounts.last[:app]).to be(app)
        expect(Pakyow.mounts.last[:path]).to be(path)
      end

      context "passed a block" do
        let :block do
          -> {}
        end

        before do
          Pakyow.mount app, at: path, &block
        end

        it "registers the block" do
          expect(Pakyow.mounts.last[:block]).to be(block)
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

    it "initializes the global logger" do
      Pakyow.instance_variable_set(:@global_logger, nil)
      Pakyow.setup

      expect(Pakyow.global_logger).to be_instance_of(Pakyow::Logger::Formatters::Human)
      expect(Pakyow.global_logger.output).to be_instance_of(Pakyow::Logger::Multiplexed)
      expect(Pakyow.global_logger.output.destinations.count).to eq(1)
    end

    it "initializes the logger" do
      Pakyow.instance_variable_set(:@logger, nil)
      Pakyow.setup

      expect(Pakyow.logger).to be_instance_of(Pakyow::Logger::ThreadLocal)
    end

    it "returns the environment" do
      expect(Pakyow.setup).to be(Pakyow)
    end
  end

  describe "::boot" do
    def perform
      Pakyow.boot
    end

    before do
      allow(Pakyow).to receive(:call_hooks)
      allow(Pakyow).to receive(:exit)

      Pakyow.mount app, at: "/"
      allow(app).to receive(:new).and_return(app_instance)
    end

    let :app do
      Class.new(Pakyow::App)
    end

    let :app_instance do
      instance_double(Pakyow::App)
    end

    it "calls after boot hooks" do
      expect(Pakyow).to receive(:call_hooks).with(:after, :boot)
      perform
    end

    it "calls booted on each app that responds to booted" do
      expect(app_instance).to receive(:booted)
      perform
    end

    it "does not call booted on an app that does not respond to booted" do
      allow(app_instance).to receive(:respond_to?)
      allow(app_instance).to receive(:respond_to?).with(:booted).and_return(false)
      expect(app_instance).to_not receive(:booted)
      perform
    end

    context "something goes wrong" do
      before do
        allow(app_instance).to receive(:booted).and_raise(error)
        allow(error).to receive(:backtrace).and_return(backtrace)
        allow(Pakyow::Support::Logging).to receive(:safe).and_yield(logger)
      end

      let :error do
        RuntimeError.new("test")
      end

      let :backtrace do
        [:foo, :bar, :baz]
      end

      let :logger do
        double(:logger, error: nil)
      end

      it "exposes the error" do
        perform
        expect(Pakyow.error).to be(error)
      end

      it "logs the error and each line of the backtrace" do
        expect(logger).to receive(:error).with(error: error)
        perform
      end

      it "exits" do
        expect(Pakyow).to receive(:exit)
        perform
      end
    end

    context "environment has already booted" do
      before do
        allow(Pakyow).to receive(:booted?).and_return(true)
      end

      it "calls booted on each app that responds to booted" do
        expect(app_instance).to receive(:booted)
        perform
      end

      it "does not call booted on an app that does not respond to booted" do
        allow(app_instance).to receive(:respond_to?)
        allow(app_instance).to receive(:respond_to?).with(:booted).and_return(false)
        expect(app_instance).to_not receive(:booted)

        perform
      end
    end
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
      Foo.constants(false).each do |const_to_unset|
        Foo.__send__(:remove_const, const_to_unset)
      end

      Bar.constants(false).each do |const_to_unset|
        Bar.__send__(:remove_const, const_to_unset)
      end

      Baz.constants(false).each do |const_to_unset|
        Baz.__send__(:remove_const, const_to_unset)
      end

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
end
