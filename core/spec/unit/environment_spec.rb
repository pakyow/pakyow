require "pakyow/application"
require "pakyow/cli"

require "pakyow/logger/thread_local"

RSpec.describe Pakyow do
  include_context "runnable"

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
        expect(Pakyow.__mounts.keys.last).to be(app)
        expect(Pakyow.__mounts.values.last[:path]).to be(path)
      end
    end

    context "called without an app" do
      it "raises an error" do
        expect {
          ignore_warnings do
            Pakyow.mount at: path
          end
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
      allow(Kernel).to receive(:load)
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
      describe "bundler reset" do
        before do
          allow(Pakyow).to receive(:require).with("pakyow/integrations/bundler/reset") do
            load "pakyow/integrations/bundler/reset.rb"
          end
        end

        context "bundler is available" do
          before do
            expect(defined?(Bundler)).to eq("constant")
          end

          it "sets up bundler" do
            expect(Bundler).to receive(:reset!)
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

          it "does not fail" do
            expect {
              Pakyow.load
            }.not_to raise_error
          end
        end
      end

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
            expect(Bundler).to receive(:setup).with(:default, :development)
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

          it "does not fail" do
            expect {
              Pakyow.load
            }.not_to raise_error
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

            ignore_warnings do
              Pakyow.load(env: :prototype)
            end
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

              ignore_warnings do
                Pakyow.load(env: :test)
              end
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
          expect(Kernel).to receive(:load).with(Pakyow.config.environment_path + ".rb")
          Pakyow.load
        end
      end
    end

    context "environment loader exists" do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(Pakyow.config.loader_path + ".rb").and_return(true)
      end

      it "requires the loader" do
        expect(Kernel).to receive(:load).with(Pakyow.config.loader_path + ".rb")
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
        expect(Kernel).to_not receive(:load).with(Pakyow.config.environment_path + "rb")
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

    it "is deprecated" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(Pakyow, :load_apps, { solution: "do not use" })
    end
  end

  describe "::setup" do
    it "calls hooks" do
      expect(Pakyow).to receive(:performing).with(:setup).and_call_original
      expect(Pakyow).to receive(:performing).with(:load).and_call_original
      expect(Pakyow).to receive(:performing).with(:configure)
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
      if Pakyow.instance_variable_defined?(:@output)
        Pakyow.remove_instance_variable(:@output)
      end

      Pakyow.setup

      expect(Pakyow.output).to be_instance_of(Pakyow::Logger::Formatters::Human)
      expect(Pakyow.output.output).to be_instance_of(Pakyow::Logger::Multiplexed)
      expect(Pakyow.output.output.destinations.count).to eq(1)
    end

    it "initializes the logger" do
      if Pakyow.instance_variable_defined?(:@logger)
        Pakyow.remove_instance_variable(:@logger)
      end

      Pakyow.setup

      expect(Pakyow.logger).to be_instance_of(Pakyow::Logger::ThreadLocal)
    end

    it "sets up each application" do
      block1 = Proc.new { "one" }
      block2 = Proc.new { "two" }
      block3 = Proc.new { "three" }

      app1 = Pakyow.app :test1, &block1
      app2 = Pakyow.app :test2, &block2
      app3 = Pakyow.app :test3, &block3

      expect(app1).to receive(:setup).with(no_args) do |&block|
        expect(block.call).to eq("one")
      end

      expect(app2).to receive(:setup).with(no_args) do |&block|
        expect(block.call).to eq("two")
      end

      expect(app3).to receive(:setup).with(no_args) do |&block|
        expect(block.call).to eq("three")
      end

      Pakyow.setup
    end

    it "returns the environment" do
      expect(Pakyow.setup).to be(Pakyow)
    end

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

    context "application config exists" do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(File.join(Pakyow.config.root, "config/application.rb")).and_return(true)
      end

      it "requires the application" do
        expect(Kernel).to receive(:load).with(File.join(Pakyow.config.root, "config/application.rb")) do; end

        Pakyow.setup
      end
    end

    context "environment is multiapp" do
      before do
        Pakyow.config.root = File.expand_path("../support/environments/multiapp", __FILE__)
      end

      it "requires each application" do
        expect(Kernel).to receive(:load).with(File.join(Pakyow.config.root, "apps/bar/config/application.rb")) do; end
        expect(Kernel).to receive(:load).with(File.join(Pakyow.config.root, "apps/foo/config/application.rb")) do; end

        Pakyow.setup
      end

      context "specific apps are mounted" do
        before do
          Pakyow.config.mounts = [:bar]
        end

        it "requires each mounted application" do
          expect(Kernel).to receive(:load).with(File.join(Pakyow.config.root, "apps/bar/config/application.rb")) do; end

          Pakyow.setup
        end

        it "does not require applications that are not mounted" do
          expect(Kernel).not_to receive(:load).with(File.join(Pakyow.config.root, "apps/foo/config/application.rb")) do; end

          Pakyow.setup
        end
      end
    end

    context "something goes wrong" do
      before do
        local = self
        Pakyow.on "setup" do
          raise local.error
        end
      end

      let(:error) {
        StandardError.new
      }

      it "raises an error" do
        expect {
          Pakyow.setup
        }.to raise_error do |raised_error|
          expect(raised_error).to be_instance_of(Pakyow::EnvironmentError)
          expect(raised_error.cause).to eq(error)
        end
      end
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
      instance_double(Pakyow::Application, booted: true, rescued?: false)
    end

    it "calls after boot hooks" do
      if Pakyow::Support::System.ruby_version < "2.7.1"
        expect(Pakyow).to receive(:call_hooks).with(:after, :boot, {})
      else
        expect(Pakyow).to receive(:call_hooks).with(:after, :boot)
      end

      perform
    end

    it "calls booted on each application" do
      expect(app_instance).to receive(:booted)
      perform
    end

    context "passed an env" do
      it "passes the env to setup" do
        expect(Pakyow).to receive(:setup).with(env: :test)

        Pakyow.boot(env: :test)
      end
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
        double(:logger, houston: nil, replace: nil)
      end

      it "raises the error" do
        expect {
          perform
        }.to raise_error do |error|
          expect(error).to be(error)
        end
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

  describe "::async" do
    before do
      allow(Async::Reactor).to receive(:run).and_return(async_context)
      allow(Pakyow).to receive(:logger).and_return(default_logger)
    end

    let(:async_context) {
      double(:async_context)
    }

    let(:default_logger) {
      double(:default_logger, target: default_logger_target)
    }

    let(:default_logger_target) {
      double(:default_logger_target)
    }

    it "returns an async reactor with the default logger target" do
      expect(Async::Reactor).to receive(:run).and_return(async_context)
      expect(Pakyow.async).to be(async_context)
    end

    it "sets the logger for the async context" do
      expect(Async::Reactor).to receive(:run) do |&block|
        expect(Pakyow.logger).to receive(:set).with(default_logger_target)

        block.call
      end

      Pakyow.async
    end

    context "passed a logger" do
      let(:logger) {
        double(:logger)
      }

      it "sets the logger for the async context" do
        expect(Async::Reactor).to receive(:run) do |&block|
          expect(Pakyow.logger).to receive(:set).with(logger)

          block.call
        end

        Pakyow.async(logger: logger)
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

    it "does not include dispatch" do
      expect(Pakyow.__pipeline.actions.find { |action| action.name == :dispatch }).to be_nil
    end

    context "after setup" do
      before do
        Pakyow.setup(env: :development)
      end

      it "includes dispatch as the last action" do
        expect(Pakyow.__pipeline.actions.last.name).to eq(:dispatch)
      end
    end
  end

  describe "restart action" do
    let :pipeline do
      Pakyow.instance_variable_get(:@__pipeline)
    end

    context "development mode" do
      before do
        Pakyow.setup(env: :development).boot
      end

      it "includes restart" do
        expect(Pakyow.__pipeline.actions.find { |action| action.name == :restart }).to_not be_nil
      end

      it "restarts before dispatch" do
        expect(pipeline.actions.map(&:name)).to eq([:handle, :missing, :log, :normalize, :parse, :restart, :dispatch])
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
        expect(pipeline.actions.map(&:name)).to eq([:handle, :missing, :log, :normalize, :parse, :restart, :dispatch])
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

  describe "limit action" do
    let(:pipeline) {
      Pakyow.instance_variable_get(:@__pipeline)
    }

    it "is not included by default" do
      expect(pipeline.actions.map(&:name)).not_to include(:limit)
    end

    context "limiter length is greater than 0" do
      before do
        Pakyow.configure do
          config.limiter.length = 1024
        end

        Pakyow.setup
      end

      it "is included" do
        expect(pipeline.actions.map(&:name)).to include(:limit)
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
      expect(Pakyow).to receive(:output).at_least(:once).and_call_original

      Pakyow::Support::Deprecator.global.ignore do
        Pakyow.global_logger
      end
    end
  end

  describe "::run" do
    it "runs the supervisor container with the expected options" do
      stub_container_run(:supervisor)

      expect(Pakyow.container(:supervisor)).to receive(:run).with(
        strategy: :hybrid,
        formation: Pakyow.config.runnable.formation,
        config: Pakyow.config.runnable,
        env: :test
      )

      Pakyow.run(env: :test)
    end

    context "passing a formation that runs all services" do
      it "runs the supervisor container with the expected options" do
        formation = Pakyow::Runnable::Formation.all(42)

        expect(Pakyow.container(:supervisor)).to receive(:run).with(
          strategy: :hybrid,
          formation: formation,
          config: Pakyow.config.runnable,
          env: :test
        ).and_yield(instance_double(Pakyow::Container, stop: nil, success?: true, running?: true))

        Pakyow.run(env: :test, formation: formation)
      end
    end

    context "passing a specific formation" do
      it "runs the specified container with the expected options" do
        stub_container_run(:environment)

        formation = Pakyow::Runnable::Formation.build(:environment) { |builder|
          builder.run(:server, 42)
        }

        expect(Pakyow.container(:environment)).to receive(:run).with(
          strategy: :hybrid,
          formation: formation,
          config: Pakyow.config.runnable,
          env: :test
        )

        Pakyow.run(env: :test, formation: formation)
      end
    end

    context "passing a formation that specifies an unknown top-level container" do
      it "fails" do
        formation = Pakyow::Runnable::Formation.build(:foo) { |builder|
          builder.run(:bar, 1)
        }

        expect {
          Pakyow.run(env: :test, formation: formation)
        }.to raise_error(Pakyow::FormationError, "`foo.bar=1' is an invalid formation because it defines a top-level container (foo) that doesn't exist")
      end
    end

    context "once the container starts" do
      before do
        allow(Pakyow).to receive(:shutdown)
      end

      it "knows that it's running" do
        ignore_warnings do
          Pakyow.run
        end

        expect(Pakyow.running?).to be(true)
      end
    end

    context "once the container stops" do
      it "says goodbye" do
        expect(Pakyow.logger).to receive(:<<).with("Goodbye")

        Pakyow.run
      end

      it "shuts down" do
        expect(Pakyow).to receive(:shutdown)

        Pakyow.run
      end

      it "exits with the container status" do
        expect(Process).to receive(:exit).with(:status)

        Pakyow.run do |instance|
          allow(instance).to receive(:success?).and_return(:status)
        end
      end

      context "environment is impolite" do
        before do
          Pakyow.config.polite = false
        end

        it "does not say goodbye" do
          expect(Pakyow.logger).not_to receive(:<<)

          Pakyow.run
        end
      end
    end

    context "container never starts" do
      before do
        allow(Pakyow.container(:supervisor)).to receive(:run).and_yield(container_double)
      end

      it "does not log the running text" do
        expect(Pakyow.logger).to receive(:<<).once.with("Goodbye")

        Pakyow.run
      end
    end

    context "environment is already running" do
      before do
        Pakyow.run
      end

      it "returns self" do
        expect(Pakyow.run).to be(Pakyow)
      end
    end

    describe "idempotence" do
      before do
        allow(container_double).to receive(:running?).and_return(true)

        stub_container_run(:supervisor)

        allow(Pakyow).to receive(:shutdown)
      end

      it "is idempotent" do
        Pakyow.run
        Pakyow.run
        Pakyow.run

        expect(Pakyow.container(:supervisor)).to have_received(:run).exactly(:once)
      end
    end

    describe "fork hooks" do
      before do
        local = self
        Pakyow.on "fork" do
          local.fork_before = true
        end

        Pakyow.after "fork" do
          local.fork_after = true
        end
      end

      attr_writer :fork_before, :fork_after

      it "calls before fork hooks" do
        Pakyow.run(env: :test)

        expect(@fork_before).to be(true)
      end

      it "calls after fork hooks" do
        Pakyow.run(env: :test)

        expect(@fork_after).to be(true)
      end
    end
  end

  describe "::shutdown" do
    context "environment is running" do
      include_context "runnable"

      before do
        stub_container_run(:supervisor)

        allow(container_double).to receive(:running?).and_return(true)

        allow(container_double).to receive(:stop) do
          allow(container_double).to receive(:running?).and_return(false)
        end

        allow(Pakyow).to receive(:shutdown)

        Pakyow.run

        allow(Pakyow).to receive(:shutdown).and_call_original
      end

      it "shuts down the container" do
        expect(container_double).to receive(:stop)

        Pakyow.shutdown
      end

      it "knows that it's shutdown" do
        expect {
          Pakyow.shutdown
        }.to change {
          Pakyow.running?
        }.from(true).to(false)
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

  describe "::restart?" do
    include_context "runnable"

    context "environment is running" do
      before do
        stub_container_run(:supervisor)

        allow(container_double).to receive(:running?).and_return(true)

        allow(Pakyow).to receive(:shutdown)

        Pakyow.run

        allow(Pakyow).to receive(:shutdown).and_call_original
      end

      it "restarts the running container" do
        expect(container_double).to receive(:restart)

        Pakyow.restart
      end

      it "passes the env" do
        expect(container_double).to receive(:restart).with(env: "foo")

        Pakyow.restart(env: "foo")
      end

      it "passes the current env when not passed" do
        expect(container_double).to receive(:restart).with(env: Pakyow.env)

        Pakyow.restart
      end
    end

    context "environment is not running" do
      it "does not restart" do
        expect(container_double).not_to receive(:restart)

        Pakyow.restart
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
      include_context "runnable"

      before do
        stub_container_run(:supervisor)

        allow(container_double).to receive(:running?).and_return(true)

        allow(Pakyow).to receive(:shutdown)

        Pakyow.run

        allow(Pakyow).to receive(:shutdown).and_call_original
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

  describe "::multiapp?" do
    context "in a default project" do
      before do
        Pakyow.config.root = File.expand_path("../support/environments/default", __FILE__)
      end

      it "returns false" do
        expect(Pakyow.multiapp?).to be(false)
      end
    end

    context "in a multiapp project" do
      before do
        Pakyow.config.root = File.expand_path("../support/environments/multiapp", __FILE__)
      end

      it "returns true" do
        expect(Pakyow.multiapp?).to be(true)
      end

      context "multiapp path is configured differently" do
        before do
          Pakyow.config.multiapp_path = File.join(Pakyow.config.root, "aaapppsss")
        end

        it "returns false" do
          expect(Pakyow.multiapp?).to be(false)
        end
      end
    end
  end
end
