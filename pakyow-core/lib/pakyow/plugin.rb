# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/configurable"
require "pakyow/support/definable"
require "pakyow/support/hookable"
require "pakyow/support/pipelined"

require "pakyow/behavior/aspects"
require "pakyow/behavior/endpoints"
require "pakyow/behavior/frameworks"
require "pakyow/behavior/helpers"
require "pakyow/behavior/isolating"
require "pakyow/behavior/pipeline"
require "pakyow/behavior/rescuing"
require "pakyow/behavior/restarting"

require "pakyow/app"

require "pakyow/plugin/helper_caller"

module Pakyow
  # Base plugin class.
  #
  class Plugin
    require "pakyow/plugin/state"

    extend Support::ClassState
    class_state :__enabled_features, default: []
    class_state :__disabled_features, default: []

    include Support::Configurable
    include Support::Definable
    include Support::Hookable
    include Support::Pipelined

    # Use the same events as app.
    #
    events(*App.events)

    # Include behavior so that plugin behaves like an app.
    #
    include Behavior::Aspects
    include Behavior::Endpoints
    include Behavior::Frameworks
    include Behavior::Helpers
    include Behavior::Isolating
    include Behavior::Pipeline
    include Behavior::Rescuing
    include Behavior::Restarting

    attr_reader :app

    def initialize(app, &block)
      super()

      @app = app
      @state = []

      performing :configure do
        configure!(@app.environment)
      end

      performing :initialize do
        if block_given?
          instance_exec(&block)
        end

        # Load state prior to calling the load hooks so that helpers are available.
        #
        load_state

        # We still want to call the load hooks so that behavior works properly.
        #
        performing :load do; end

        defined!
      end

      create_helper_contexts

      if respond_to?(:boot)
        boot
      end
    end

    def call(connection)
      connection.instance_variable_set(:@app, self)
      super(connection)
      connection.instance_variable_set(:@app, @app)
    end

    def method_missing(method_name, *args, &block)
      if @app.respond_to?(method_name)
        @app.public_send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @app.respond_to?(method_name) || super
    end

    def helpers(connection)
      @helper_class.new(self, connection)
    end

    def __object_name
      self.class.__object_name
    end

    def helper_caller(context, connection)
      HelperCaller.new(
        plugin: self,
        connection: connection,
        helpers: @helper_contexts[context.to_sym].new(connection)
      )
    end

    private

    def load_aspect(aspect)
      @state.each do |state|
        super(aspect, path: state.backend_path(aspect), target: self)
      end
    end

    def load_state
      load_global_state
      load_feature_state
    end

    def load_global_state
      @state << State.new(self)
    end

    def load_feature_state
      self.class.features.each do |feature|
        @state << State.new(self, path: feature[:path])
      end
    end

    def create_helper_contexts
      @helper_contexts = %i(global passive active).each_with_object({}) { |context, helper_contexts|
        helper_class = Class.new do
          def initialize(connection)
            @connection = connection
          end
        end

        self.class.include_helpers(context, helper_class)
        helper_contexts[context] = helper_class
      }
    end

    class << self
      attr_reader :plugin_name, :plugin_path, :mount_path

      # rubocop:disable Naming/MethodName
      def Plugin(name, path)
        Class.new(self) do
          @plugin_name = name
          @plugin_path = path
        end
      end
      # rubocop:enabled Naming/MethodName

      def inherited(plugin_class)
        super

        if instance_variable_defined?(:@plugin_name)
          plugin_class.instance_variable_set(:@plugin_name, instance_variable_get(:@plugin_name))
          plugin_class.instance_variable_set(:@plugin_path, instance_variable_get(:@plugin_path))

          Pakyow.register_plugin(@plugin_name, plugin_class)
        end
      end

      def enable(*features)
        @__enabled_features.concat(features)
      end

      def disable(*features)
        @__disabled_features.concat(features)
      end

      def features
        Dir.glob(File.join(plugin_path, "features", "*")).map { |feature_path|
          {
            name: File.basename(feature_path).to_sym,
            path: feature_path
          }
        }.tap do |features|
          features.delete_if do |feature|
            @__disabled_features.include?(feature[:name])
          end

          if @__enabled_features.any?
            features.keep_if do |feature|
              @__enabled_features.include?(feature[:name])
            end
          end
        end
      end
    end

    context = self
    Pakyow.singleton_class.class_eval do
      define_method :Plugin do |name, path|
        context.Plugin(name, path)
      end
    end
  end
end
