# frozen_string_literal: true

require "async"

require "console"
require "console/split"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/definable"
require "pakyow/support/pipeline"
require "pakyow/support/inflector"
require "pakyow/support/deprecatable"

require "pakyow/behavior/commands"
require "pakyow/behavior/deprecations"
require "pakyow/behavior/initializers"
require "pakyow/behavior/input_parsing"
require "pakyow/behavior/plugins"
require "pakyow/behavior/silencing"
require "pakyow/behavior/tasks"
require "pakyow/behavior/timezone"
require "pakyow/behavior/running"
require "pakyow/behavior/watching"
require "pakyow/behavior/restarting"
require "pakyow/behavior/verifier"

require "pakyow/actions/dispatch"
require "pakyow/actions/input_parser"
require "pakyow/actions/logger"
require "pakyow/actions/normalizer"
require "pakyow/actions/restart"

require "pakyow/application"

require "pakyow/logger"
require "pakyow/logger/destination"
require "pakyow/logger/multiplexed"
require "pakyow/logger/thread_local"

# Pakyow environment for running one or more rack apps. Multiple apps can be
# mounted in the environment, each one handling requests at some path.
#
#   Pakyow.configure do
#     mount Pakyow::Application, at: "/"
#   end
#
# = Configuration
#
# The environment can be configured
#
#   Pakyow.configure do
#     config.server.port = 2001
#   end
#
# It's possible to configure environments differently.
#
#   Pakyow.configure :development do
#     config.server.host = "pakyow.dev"
#   end
#
# @see Support::Configurable
#
# = Hooks
#
# Hooks can be defined for the following events:
#
#   - load
#   - configure
#   - setup
#   - boot
#   - shutdown
#   - run
#
# Here's how to log a message after boot:
#
#   Pakyow.after "boot" do
#     logger.info "booted"
#   end
#
# @see Support::Hookable
#
# = Logging
#
# The environment contains a global general-purpose logger. It also provides
# a {RequestLogger} instance to each app for logging during a request.
#
# = Setup & Running
#
# The environment can be setup and then run.
#
#   Pakyow.setup(env: :development).run
#
module Pakyow
  using Support::DeepDup
  using Support::DeepFreeze
  using Support::Refinements::Array::Ensurable

  include Support::Hookable
  events :load, :configure, :setup, :boot, :shutdown, :run

  include Support::Configurable

  setting :default_env, :development
  setting :freeze_on_boot, true
  setting :exit_on_boot_failure, true
  setting :timezone, :utc
  setting :secrets, ["pakyow"]

  setting :connection_class do
    require "pakyow/connection"
    Connection
  end

  setting :root do
    File.expand_path(".")
  end

  setting :lib do
    File.join(config.root, "lib")
  end

  setting :environment_path do
    File.join(config.root, "config/environment")
  end

  setting :loader_path do
    File.join(config.root, "config/loader")
  end

  defaults :test do
    setting :exit_on_boot_failure, false
  end

  defaults :production do
    setting :secrets, [ENV["SECRET"].to_s.strip]
  end

  config.deprecate :freeze_on_boot

  configurable :server do
    setting :host, "localhost"
    setting :port, 3000
    setting :count, 1
    setting :proxy, true

    defaults :production do
      setting :proxy, false

      setting :host do
        ENV["HOST"] || "0.0.0.0"
      end

      setting :port do
        ENV["PORT"] || 3000
      end

      setting :count do
        ENV["WORKERS"] || 5
      end
    end
  end

  configurable :cli do
    setting :repl do
      require "irb"; IRB
    end
  end

  configurable :logger do
    setting :enabled, true
    setting :sync, true

    setting :level do
      if config.logger.enabled
        :debug
      else
        :off
      end
    end

    setting :formatter do
      require "pakyow/logger/formatters/human"
      Logger::Formatters::Human
    end

    setting :destinations do
      if config.logger.enabled
        { stdout: $stdout }
      else
        {}
      end
    end

    defaults :test do
      setting :enabled, false
    end

    defaults :production do
      setting :level do
        if config.logger.enabled
          :info
        else
          :off
        end
      end

      setting :formatter do
        require "pakyow/logger/formatters/logfmt"
        Logger::Formatters::Logfmt
      end
    end

    defaults :ludicrous do
      setting :enabled, false
    end
  end

  configurable :normalizer do
    setting :canonical_uri

    setting :strict_path, true

    setting :strict_www, false
    setting :require_www, true

    setting :strict_https, false
    setting :require_https, true
    setting :allowed_http_hosts, ["localhost"]

    defaults :production do
      setting :strict_https, true
    end
  end

  configurable :redis do
    configurable :connection do
      setting :url do
        ENV["REDIS_URL"] || "redis://127.0.0.1:6379"
      end

      setting :timeout, 5
      setting :driver, nil
      setting :id, nil
      setting :tcp_keepalive, 5
      setting :reconnect_attempts, 1
      setting :inherit_socket, false
    end

    configurable :pool do
      setting :size, 3
      setting :timeout, 1
    end

    setting :key_prefix, "pw"
  end

  configurable :cookies do
    setting :domain
    setting :path, "/"
    setting :max_age
    setting :expires
    setting :secure
    setting :http_only
    setting :same_site
  end

  include Support::Definable

  include Behavior::Commands
  include Behavior::Initializers
  include Behavior::InputParsing
  include Behavior::Plugins
  include Behavior::Silencing
  include Behavior::Tasks
  include Behavior::Timezone
  include Behavior::Running
  include Behavior::Watching
  include Behavior::Restarting
  include Behavior::Verifier

  include Support::Pipeline
  action :log, Actions::Logger
  action :normalize, Actions::Normalizer
  action :parse, Actions::InputParser
  action :dispatch, Actions::Dispatch

  before :configure do
    if env?(:development) || env?(:prototype)
      action :restart, Actions::Restart, before: :dispatch
    end
  end

  extend Support::ClassState
  class_state :apps,        default: []
  class_state :mounts,      default: []
  class_state :setups,      default: {}
  class_state :frameworks,  default: {}
  class_state :booted,      default: false, reader: false
  class_state :server,      default: nil, reader: false
  class_state :env,         default: nil, reader: false
  class_state :setup_error, default: nil

  class << self
    extend Support::Deprecatable

    # Name of the environment
    #
    attr_reader :env

    # Any error encountered during the boot process
    #
    attr_reader :error

    # Global log output.
    #
    # Builds and returns a default global output that's replaced in `setup`.
    #
    def output
      unless defined?(@output)
        require "pakyow/logger/formatters/human"
        @output = Logger::Formatters::Human.new(
          Logger::Destination.new(:stdout, $stdout)
        )
      end

      @output
    end

    # @deprecated Use {output} instead.
    #
    def global_logger
      output
    end
    deprecate :global_logger, solution: "use `output'"

    # Logger instance for the environment.
    #
    # Builds and returns a default logger that's replaced in `setup`.
    #
    def logger
      @logger ||= Logger::ThreadLocal.new(Logger.new("dflt", output: output, level: :all), key: :pakyow_logger)
    end

    # Mounts an app at a path. The app can be any object that responds to `call`.
    #
    # @param app [Object] the app object to mount
    # @param at [String] where the endpoint should be mounted
    #
    def mount(app, at:)
      mounts << { app: app, path: at }
    end

    # Loads the Pakyow environment for the current project.
    #
    def load
      performing :load do
        if File.exist?(config.loader_path + ".rb")
          require config.loader_path
        else
          require "pakyow/integrations/bundler/setup"
          require "pakyow/integrations/bootsnap"

          require "pakyow/integrations/bundler/require"
          require "pakyow/integrations/dotenv"

          require config.environment_path

          load_apps
        end
      end
    end

    # Loads apps located in the current project.
    #
    def load_apps
      require File.join(config.root, "config/application")
    end

    # Prepares the environment for booting.
    #
    # @param env [Symbol] the environment to prepare for
    #
    def setup(env: nil)
      @env = (env ||= config.default_env).to_sym

      load

      performing :configure do
        configure!(env)
        $LOAD_PATH.unshift(config.lib)
      end

      performing :setup do
        destinations = Logger::Multiplexed.new(
          *config.logger.destinations.map { |destination, io|
            io.sync = config.logger.sync
            Logger::Destination.new(destination, io)
          }
        )

        @output = config.logger.formatter.new(destinations)

        # Replace the default logger with a configured logger. We don't overwrite `@logger` here so
        # that objects that hold a reference to the thread local logger before setup still point to
        # the right object and log to the appropriate logger after setup.
        #
        logger.replace(Logger.new("pkyw", output: @output, level: config.logger.level))

        Console.logger = Logger.new("asnc", output: @output, level: :warn)
      end

      self
    rescue => error
      @setup_error = error; self
    end

    # Returns true if the environment has booted.
    #
    def booted?
      @booted == true
    end

    # Boots the environment without running it.
    #
    def boot(unsafe: false)
      ensure_setup_succeeded

      performing :boot do
        # Tasks should only be available before boot.
        # TODO: Move this into CLI-specific behavior once `unsafe` is removed.
        #
        @tasks = [] unless unsafe

        # Setup each app.
        #
        mounts.map { |mount| mount[:app] }.uniq.each do |app|
          if block = setups[app]
            app.setup(&block)
          else
            app.setup
          end
        end

        # Mount each app.
        #
        @apps = mounts.map { |mount|
          initialize_app_for_mount(mount)
        }

        # Create the callable pipeline.
        #
        @pipeline = Pakyow.__pipeline.callable(self)

        # Set the environment as booted ahead of telling each app that it is booted. This allows an
        # app's after boot hook to access the booted app through `Pakyow.app`.
        #
        @booted = true

        # Now tell each app that it has been booted.
        #
        @apps.select { |app| app.respond_to?(:booted) }.each(&:booted)
      end

      self
    rescue StandardError => error
      handle_boot_failure(error)
    end

    def register_framework(framework_name, framework_module)
      @frameworks[framework_name] = framework_module
    end

    def app(app_name, path: "/", without: [], only: nil, mount: true, &block)
      app_name = app_name.to_sym

      if booted?
        @apps.find { |app|
          app.config.name == app_name
        }
      else
        local = self
        Pakyow::Application.make(Support::ObjectName.build(app_name, "application")) {
          config.name = app_name

          # Including frameworks during make lets frameworks attach `after :make` hooks.
          #
          include_frameworks(*(only || local.frameworks.keys) - Array.ensure(without))
        }.tap do |app|
          @setups[app] = block if block_given?
          mount(app, at: path) if mount
        end
      end
    end

    def env?(name)
      env == name.to_sym
    end

    def call(input)
      config.connection_class.new(input).yield_self { |connection|
        connection.async {
          catch :halt do
            @pipeline.call(connection)
          end
        }.wait
      }.finalize
    rescue StandardError => error
      Pakyow.logger.houston(error)

      Async::HTTP::Protocol::Response.new(
        nil, 500, {}, Async::HTTP::Body::Buffered.wrap(
          StringIO.new("500 Low-Level Server Error")
        )
      )
    end

    # @api private
    def initialize_app_for_mount(mount)
      if mount[:app].ancestors.include?(Pakyow::Application)
        mount[:app].new(mount_path: mount[:path])
      else
        mount[:app].new
      end
    end

    private

    def ensure_setup_succeeded
      if @setup_error
        handle_boot_failure(@setup_error)
      end
    end

    def handle_boot_failure(error)
      @error = error

      logger.houston(error)

      if config.exit_on_boot_failure
        exit(false)
      end
    end
  end

  include Behavior::Deprecations
end
