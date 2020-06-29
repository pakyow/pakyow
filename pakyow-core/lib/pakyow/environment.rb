# frozen_string_literal: true

require "async"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/definable"
require "pakyow/support/handleable"
require "pakyow/support/pipeline"
require "pakyow/support/deprecatable"

require_relative "behavior/commands"
require_relative "behavior/deprecations"
require_relative "behavior/dispatching"
require_relative "behavior/erroring"
require_relative "behavior/generators"
require_relative "behavior/initializers"
require_relative "behavior/input_parsing"
require_relative "behavior/multiapp"
require_relative "behavior/plugins"
require_relative "behavior/release_channels"
require_relative "behavior/rescuing"
require_relative "behavior/silencing"
require_relative "behavior/tasks"
require_relative "behavior/timezone"
require_relative "behavior/running"
require_relative "behavior/watching"
require_relative "behavior/restarting"
require_relative "behavior/verifier"

require_relative "actions/input_parser"
require_relative "actions/logger"
require_relative "actions/missing"
require_relative "actions/normalizer"
require_relative "actions/restart"

require_relative "handleable/actions/handle"
require_relative "handleable/behavior/statuses"
require_relative "handleable/behavior/defaults/not_found"
require_relative "handleable/behavior/defaults/server_error"

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
#     config.runnable.server.port = 2001
#   end
#
# It's possible to configure environments differently.
#
#   Pakyow.configure :development do
#     config.runnable.server.host = "pakyow.dev"
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
  events :load, :configure, :setup, :boot, :shutdown, :run, :error

  include Support::Configurable

  setting :default_env, :development
  setting :freeze_on_boot, true
  setting :exit_on_boot_failure, false
  setting :timezone, :utc
  setting :secrets, ["pakyow"]
  setting :channel, :default

  require "pakyow/connection"
  setting :connection_class, Connection

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

  setting :mounts do
    :all
  end

  defaults :test do
    setting :exit_on_boot_failure, false
  end

  defaults :production do
    setting :secrets, [ENV["SECRET"].to_s.strip]
  end

  config.deprecate :freeze_on_boot
  config.deprecate :exit_on_boot_failure

  configurable :runnable do
    setting :formation do
      Runnable::Formation.all
    end

    configurable :server do
      setting :count, 1
      setting :scheme, "http"
      setting :host, "localhost"
      setting :port, 3000

      defaults :production do
        setting :count do
          ENV["WORKERS"] || 5
        end

        setting :host do
          ENV["HOST"] || "0.0.0.0"
        end

        setting :port do
          ENV["PORT"] || 3000
        end
      end
    end

    configurable :watcher do
      setting :enabled, true

      setting :count do
        config.runnable.watcher.enabled ? 1 : 0
      end
    end
  end

  configurable :server do
    setting :restartable, true
    deprecate :restartable

    setting :host, "localhost"
    remove_method :host=
    def host=(value); Pakyow.config.runnable.server.host = value; end
    deprecate :host, solution: "use `config.runnable.server.host'"

    setting :port, 3000
    remove_method :port=
    def port=(value); Pakyow.config.runnable.server.port = value; end
    deprecate :port, solution: "use `config.runnable.server.port'"

    setting :count, 1
    remove_method :count=
    def count=(value); Pakyow.config.runnable.server.count = value; end
    deprecate :count, solution: "use `config.runnable.server.count'"

    setting :proxy, true
    deprecate :proxy

    defaults :production do
      setting :proxy, false
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
      setting :sync, false

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
  include Support::Handleable

  include Behavior::Commands
  include Behavior::Dispatching
  include Behavior::Erroring
  include Behavior::Generators
  include Behavior::Initializers
  include Behavior::InputParsing
  include Behavior::Multiapp
  include Behavior::Plugins
  include Behavior::ReleaseChannels
  include Behavior::Rescuing
  include Behavior::Silencing
  include Behavior::Tasks
  include Behavior::Timezone
  include Behavior::Running
  include Behavior::Watching
  include Behavior::Restarting
  include Behavior::Verifier

  include Handleable::Behavior::Statuses

  include Handleable::Behavior::Defaults::NotFound
  include Handleable::Behavior::Defaults::ServerError

  include Support::Pipeline
  action :handle, Handleable::Actions::Handle
  action :missing, Actions::Missing
  action :log, Actions::Logger
  action :normalize, Actions::Normalizer
  action :parse, Actions::InputParser

  before :configure do
    if env?(:development) || env?(:prototype)
      action :restart, Actions::Restart
    end
  end

  extend Support::ClassState
  class_state :apps,        default: []
  class_state :__mounts,    default: {}
  class_state :__setups,    default: {}
  class_state :frameworks,  default: {}
  class_state :__loaded,    default: false, reader: false
  class_state :__setup,     default: false, reader: false
  class_state :__booted,    default: false, reader: false
  class_state :server,      default: nil, reader: false
  class_state :env,         default: nil, reader: false
  class_state :setup_error, default: nil

  class << self
    extend Support::Deprecatable

    # Name of the environment
    #
    attr_reader :env

    # Global log output.
    #
    # Builds and returns a default global output that's replaced in `setup`.
    #
    def output
      unless defined?(@output)
        require "pakyow/logger/destination"
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
      unless defined?(@logger)
        require "pakyow/logger/thread_local"
        @logger = Logger::ThreadLocal.new(
          Logger.new("dflt", output: output, level: :all), key: :pakyow_logger
        )
      end

      @logger
    end

    # Mounts an app at a path. The app can be any object that responds to `call`.
    #
    # @param app [Object] the app object to mount
    # @param at [String] where the endpoint should be mounted
    #
    def mount(app, at:)
      @__mounts[app] = { path: at }
    end

    # Loads the Pakyow environment for the current project.
    #
    def load(env: nil)
      unless loaded?
        @env = (env ||= config.default_env).to_sym

        performing :load do
          if File.exist?(config.loader_path + ".rb")
            Kernel.load config.loader_path + ".rb"
          else
            require "pakyow/integrations/bundler/reset"
            require "pakyow/integrations/bundler/setup"
            require "pakyow/integrations/bootsnap"

            require "pakyow/integrations/bundler/require"
            require "pakyow/integrations/dotenv"

            if File.exist?(config.environment_path + ".rb")
              Kernel.load config.environment_path + ".rb"
            end
          end

          performing :configure do
            configure!(env)
          end

          $LOAD_PATH.unshift(config.lib)
        end

        @__loaded = true
      end
    rescue ApplicationError => error
      raise error
    rescue ScriptError, StandardError => error
      raise EnvironmentError.build(error)
    end

    # Returns true if the environment has loaded.
    #
    def loaded?
      @__loaded == true
    end

    # Prepares the environment for booting by setting up internal state, including applications.
    #
    # @param env [Symbol] the environment to prepare for
    #
    def setup(env: nil)
      unless setup?
        load(env: env)

        performing :setup do
          require "console"
          require "console/split"

          require "pakyow/logger"
          require "pakyow/logger/destination"
          require "pakyow/logger/multiplexed"

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

          # Setup each app.
          #
          load_apps_common
          mounts.keys.uniq.each do |app|
            setups = @__setups[app]
            if setups.nil? || setups.empty?
              app.setup
            else
              setups.each do |block|
                app.setup(&block)
              end
            end
          end

          @apps = mounts.map { |app, options|
            app.new(mount_path: options[:path])
          }

          @__setup = true
        end
      end

      self
    rescue ApplicationError => error
      raise error
    rescue ScriptError, StandardError => error
      raise EnvironmentError.build(error)
    end

    # Returns true if the environment has been setup.
    #
    def setup?
      @__setup == true
    end

    # Boots the environment so that it can be used, without running it.
    #
    # @param env [Symbol] the environment to prepare for
    #
    def boot(env: nil)
      unless booted?
        setup(env: env)

        performing :boot do
          # Set the environment as booted ahead of telling each app that it is booted. This allows an
          # app's after boot hook to access the booted app through `Pakyow.app`.
          #
          @__booted = true

          # Now tell each app that it has been booted.
          #
          @apps.each(&:booted)
        end
      end

      self
    rescue ApplicationError => error
      raise error
    rescue ScriptError, StandardError => error
      raise EnvironmentError.build(error)
    end

    # Returns true if the environment has booted.
    #
    def booted?
      @__booted == true
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
        require "pakyow/application"
        Pakyow::Application.make(Support::ObjectName.build(app_name, "application")) {
          # Change the name only if it's still the default. It's possible the app has already been
          # defined and we're simply extending it.
          #
          config.name = app_name if config.name == :pakyow

          # Including frameworks during make lets frameworks attach `after :make` hooks.
          #
          include_frameworks(*(only || local.frameworks.keys) - Array.ensure(without))
        }.tap do |app|
          @__setups[app] ||= []
          @__setups[app] << block if block_given?

          mount(app, at: path) if mount
        end
      end
    end

    def env?(name)
      env == name.to_sym
    end

    def async(logger: self.logger, &block)
      Async::Reactor.run(logger: logger, &block)
    end

    def call(input)
      connection = config.connection_class.new(input)
      connection.async { super(connection) }.wait
      connection.finalize
    rescue StandardError => error
      houston(error)

      Async::HTTP::Protocol::Response.new(
        nil, 500, {}, Async::HTTP::Body::Buffered.wrap(
          StringIO.new("500 Low-Level Server Error")
        )
      )
    end

    # @deprecated
    def load_apps
      load_apps_common
    end
    deprecate :load_apps

    private def load_apps_common
      if File.exist?(File.join(config.root, "config/application.rb"))
        Kernel.load File.join(config.root, "config/application.rb")
      end
    end

    # Returns applications eligble to be mounted, based on `config.mounts`.
    #
    private def mounts
      @__mounts.keep_if { |app|
        config.mounts == :all || config.mounts.include?(app.config.name)
      }
    end
  end

  include Behavior::Deprecations
end
