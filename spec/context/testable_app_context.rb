RSpec.shared_context "testable app" do
  let :app do
    Pakyow::App
  end

  let :app_runtime_block do
    Proc.new {}
  end

  let :autorun do
    true
  end

  before do
    Pakyow.config.server.default = :mock

    if app_definition
      app.define(&app_definition)
      run if autorun
    end
  end

  after do
    Pakyow.reset
    app.reset
  end
end

module Pakyow::Support::Definable
  def deep_freeze
    # noop; we don't want to freeze in our own specs because we want we want each group of tests
    # to register new state; this can't happen if definables are frozen
  end
end

# Define all the necessary reset methods for cleaning up between runs.
#
module Pakyow
  class << self
    def reset
      @env = nil
      @port = nil
      @host = nil
      @server = nil
      @mounts = nil
      @builder = nil
      @logger = nil
      config.reset
    end
  end

  class Router
    class << self
      def reset
        @hooks = { before: [], after: [], around: [] }
        @children = []
        @templates = {}
        @handlers = {}
        @exceptions = {}
      end
    end
  end

  module Presenter
    class TemplateStore
      class << self
        def reset
          # TODO: what should we do here?
        end
      end
    end

    class ViewPresenter
      class << self
        def reset
          # TODO: what should we do here?
        end
      end
    end

    class Binder
      class << self
        def reset
          # TODO: what should we do here?
        end
      end
    end
  end

  module Support
    class State
      def reset
        object.reset
        @instances = []
      end
    end

    module Configurable
      class Config
        def reset
          @groups.each do |_, group|
            group.reset
          end
        end
      end

      class ConfigGroup
        using DeepDup

        def reset
          @__settings = @__initial_settings.deep_dup

          @__settings.each do |_, settings|
            settings.reset
          end
        end
      end

      class ConfigOption
        def reset
          if instance_variable_defined?(:@value)
            remove_instance_variable(:@value)
          end
        end
      end

      module ClassAPI
        def reset
          super if defined? super
          @config_envs = nil
          config.reset
        end
      end
    end

    module Definable
      module ClassAPI
        def reset
          super if defined? super
          @state.values.each do |state|
            state.reset
          end
        end
      end
    end
  end
end
