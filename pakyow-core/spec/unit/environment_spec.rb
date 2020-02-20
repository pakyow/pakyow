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
      allow(Pakyow).to receive(:performing).and_call_original
    end

    it "performs the load event" do
      expect(Pakyow).to receive(:performing).with(:load)

      Pakyow.load
    end

    it "performs the configure event" do
      expect(Pakyow).to receive(:performing).with(:configure)

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
          allow(Pakyow).to receive(:performing).with(:configure)

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
            expect(Bundler).to receive(:require).with(:default, :development)
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

        context "in prototype mode" do
          it "requires the default and development bundles" do
            expect(Bundler).to receive(:require).with(:default, :development)
            Pakyow.load(env: :prototype)
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
              allow(Dotenv).to receive(:load)
              allow(File).to receive(:exist?)
              allow(File).to receive(:exist?).with(".env.test").and_return(true)
            end

            it "loads the environment-specific dotfile" do
              expect(Dotenv).to receive(:load).with(".env.test")
              Pakyow.load(env: :test)
            end

            it "loads dotenv" do
              expect(Dotenv).to receive(:load).with(no_args)
              Pakyow.load(env: :test)
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

      context "environment config exists" do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(Pakyow.config.environment_path + ".rb").and_return(true)
        end

        it "requires the environment" do
          expect(Pakyow).to receive(:require).with(Pakyow.config.environment_path)
          Pakyow.load
        end
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

    describe "idempotence" do
      before do
        allow(Pakyow).to receive(:performing).and_call_original
      end

      it "is idempotent" do
        Pakyow.load
        Pakyow.load
        Pakyow.load

        expect(Pakyow).to have_received(:performing).with(:load).exactly(:once)
      end
    end
  end

  describe "::load_apps" do
    after do
      Pakyow.load_apps
    end

    context "application config exists" do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(File.join(Pakyow.config.root, "config/application.rb")).and_return(true)
      end

      it "requires the application" do
        expect(Pakyow).to receive(:require).with(File.join(Pakyow.config.root, "config/application")) do; end
      end
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
      expect(Pakyow).to receive(:performing).with(:setup).and_call_original
      expect(Pakyow).to receive(:performing).with(:configure)
      expect(Pakyow).to receive(:performing).with(:load)
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

    it "initializes the environment output" do
      Pakyow.instance_variable_set(:@output, nil)
      Pakyow.setup

      expect(Pakyow.output).to be_instance_of(Pakyow::Logger::Formatters::Human)
      expect(Pakyow.output.output).to be_instance_of(Pakyow::Logger::Multiplexed)
      expect(Pakyow.output.output.destinations.count).to eq(1)
    end

    it "initializes the logger" do
      Pakyow.instance_variable_set(:@logger, nil)
      Pakyow.setup

      expect(Pakyow.logger).to be_instance_of(Pakyow::Logger::ThreadLocal)
    end

    it "returns the environment" do
      expect(Pakyow.setup).to be(Pakyow)
    end

    describe "idempotence" do
      before do
        allow(Pakyow).to receive(:performing).and_call_original
      end

      it "is idempotent" do
        Pakyow.setup
        Pakyow.setup
        Pakyow.setup

        expect(Pakyow).to have_received(:performing).with(:setup).exactly(:once)
      end
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
      Pakyow::Application.make(:test)
    end

    let :app_instance do
      instance_double(Pakyow::Application)
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
        allow(Pakyow).to receive(:logger).and_return(logger)
      end

      let :error do
        RuntimeError.new("test")
      end

      let :backtrace do
        [:foo, :bar, :baz]
      end

      let :logger do
        double(:logger, houston: nil)
      end

      it "exposes the error" do
        perform
        expect(Pakyow.error).to be(error)
      end

      it "logs the error and each line of the backtrace" do
        expect(logger).to receive(:houston).with(error)
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

      it "does not call booted on any app" do
        expect(app_instance).not_to receive(:booted)
        perform
      end
    end

    describe "idempotence" do
      before do
        allow(Pakyow).to receive(:performing).and_call_original
      end

      it "is idempotent" do
        Pakyow.boot
        Pakyow.boot
        Pakyow.boot

        expect(Pakyow).to have_received(:performing).with(:boot).exactly(:once)
      end
    end
  end

  describe "::apps" do
    include_context "app"

    let :app do
      Pakyow::Application.make(:test)
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
      Pakyow.app :test_foo, path: "/foo"
      Pakyow.app :test_bar, path: "/bar"
      Pakyow.app :test_baz, path: "/baz"

      Pakyow.boot
    end

    context "environment has booted" do
      before do
        Pakyow.setup(env: :test).boot
      end

      it "returns an app instance" do
        expect(Pakyow.app(:test_foo).config.name).to eq(:test_foo)
        expect(Pakyow.app(:test_bar).config.name).to eq(:test_bar)
        expect(Pakyow.app(:test_baz).config.name).to eq(:test_baz)
      end
    end
  end

  describe "default actions" do
    it "includes log" do
      expect(Pakyow.__pipeline.actions.find { |action| action.name == :log }).to_not be_nil
    end

    it "includes normalize" do
      expect(Pakyow.__pipeline.actions.find { |action| action.name == :normalize }).to_not be_nil
    end

    it "includes parse" do
      expect(Pakyow.__pipeline.actions.find { |action| action.name == :parse }).to_not be_nil
    end

    it "includes dispatch" do
      expect(Pakyow.__pipeline.actions.find { |action| action.name == :dispatch }).to_not be_nil
    end
  end

  describe "restart action" do
    let :pipeline do
      Pakyow.instance_variable_get(:@pipeline)
    end

    context "development mode" do
      before do
        Pakyow.setup(env: :development).boot
      end

      it "includes restart" do
        expect(Pakyow.__pipeline.actions.find { |action| action.name == :restart }).to_not be_nil
      end

      it "restarts before dispatch" do
        expect(pipeline.instance_variable_get(:@stack).map(&:owner).map(&:name)).to eq(
          [
            "Pakyow::Actions::Logger",
            "Pakyow::Actions::Normalizer",
            "Pakyow::Actions::InputParser",
            "Pakyow::Actions::Restart",
            "Pakyow::Actions::Dispatch"
          ]
        )
      end
    end

    context "prototype mode" do
      before do
        Pakyow.setup(env: :prototype).boot
      end

      it "includes restart" do
        expect(Pakyow.__pipeline.actions.find { |action| action.name == :restart }).to_not be_nil
      end

      it "restarts before dispatch" do
        expect(pipeline.instance_variable_get(:@stack).map(&:owner).map(&:name)).to eq(
          [
            "Pakyow::Actions::Logger",
            "Pakyow::Actions::Normalizer",
            "Pakyow::Actions::InputParser",
            "Pakyow::Actions::Restart",
            "Pakyow::Actions::Dispatch"
          ]
        )
      end
    end

    context "production mode" do
      before do
        Pakyow.setup(env: :production)
      end

      it "does not include restart" do
        expect(Pakyow.__pipeline.actions.find { |action| action.name == :restart }).to be_nil
      end
    end
  end

  describe "::output" do
    it "is memoized" do
      expect(Pakyow.output).to be(Pakyow.output)
    end
  end

  describe "::logger" do
    it "is memoized" do
      expect(Pakyow.logger).to be(Pakyow.logger)
    end
  end

  describe "::global_logger" do
    it "is deprecated" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        Pakyow, :global_logger, solution: "use `output'"
      )

      Pakyow.global_logger
    end

    it "calls ::output" do
      allow(Pakyow).to receive(:deprecated)
      expect(Pakyow).to receive(:output).at_least(:once).and_call_original

      Pakyow.global_logger
    end
  end

  describe "::run" do
    describe "idempotence" do
      before do
        allow(Async::Reactor).to receive(:run) do |&block|
          block.call
        end

        allow(Pakyow).to receive(:boot)
        allow(Pakyow).to receive(:call_hooks)
        allow(Pakyow).to receive(:start_processes).and_return(instance_double(Thread, join: nil))
      end

      it "is idempotent" do
        Pakyow.run
        Pakyow.run
        Pakyow.run

        expect(Async::Reactor).to have_received(:run).exactly(:once)
      end
    end
  end

  describe "::shutdown" do
    context "environment is running" do
      before do
        allow(Async::Reactor).to receive(:run) do |&block|
          block.call
        end

        allow(Pakyow).to receive(:boot)
        allow(Pakyow).to receive(:call_hooks)
        allow(Pakyow).to receive(:start_processes).and_return(instance_double(Thread, join: nil))

        Pakyow.run

        Pakyow.instance_variable_set(:@filewatcher, double(stop: nil))
        Pakyow.instance_variable_set(:@__reactor, double(stop: nil))
      end

      describe "idempotence" do
        before do
          allow(Pakyow).to receive(:performing).and_call_original
        end

        it "is idempotent" do
          Pakyow.shutdown
          Pakyow.shutdown
          Pakyow.shutdown

          expect(Pakyow).to have_received(:performing).with(:shutdown).exactly(:once)
        end
      end
    end

    context "environment is not running" do
      before do
        allow(Pakyow).to receive(:performing).and_call_original
      end

      it "does not shutdown" do
        expect(Pakyow).not_to have_received(:performing).with(:shutdown)
      end
    end
  end

  describe "::loaded?" do
    context "environment is loaded" do
      before do
        Pakyow.load
      end

      it "returns true" do
        expect(Pakyow.loaded?).to be(true)
      end
    end

    context "environment is not loaded" do
      it "returns false" do
        expect(Pakyow.loaded?).to be(false)
      end
    end
  end

  describe "::setup?" do
    context "environment is setup" do
      before do
        Pakyow.setup
      end

      it "returns true" do
        expect(Pakyow.setup?).to be(true)
      end
    end

    context "environment is not setup" do
      it "returns false" do
        expect(Pakyow.setup?).to be(false)
      end
    end
  end

  describe "::booted?" do
    context "environment is booted" do
      before do
        Pakyow.boot
      end

      it "returns true" do
        expect(Pakyow.booted?).to be(true)
      end
    end

    context "environment is not booted" do
      it "returns false" do
        expect(Pakyow.booted?).to be(false)
      end
    end
  end

  describe "::running?" do
    context "environment is running" do
      before do
        allow(Async::Reactor).to receive(:run) do |&block|
          block.call
        end

        allow(Pakyow).to receive(:boot)
        allow(Pakyow).to receive(:call_hooks)
        allow(Pakyow).to receive(:start_processes).and_return(instance_double(Thread, join: nil))

        Pakyow.run
      end

      it "returns true" do
        expect(Pakyow.running?).to be(true)
      end
    end

    context "environment is not running" do
      it "returns false" do
        expect(Pakyow.running?).to be(false)
      end
    end
  end
end
