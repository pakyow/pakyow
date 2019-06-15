# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/configurable"
require "pakyow/support/definable"
require "pakyow/support/hookable"
require "pakyow/support/pipeline"

require "pakyow/behavior/aspects"
require "pakyow/behavior/endpoints"
require "pakyow/behavior/frameworks"
require "pakyow/behavior/helpers"
require "pakyow/behavior/isolating"
require "pakyow/behavior/operations"
require "pakyow/behavior/pipeline"
require "pakyow/behavior/rescuing"
require "pakyow/behavior/restarting"

require "pakyow/app"
require "pakyow/endpoints"

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

    setting :name

    setting :root do
      plugin_path
    end

    setting :src do
      File.join(config.root, "backend")
    end

    setting :lib do
      File.join(config.src, "lib")
    end

    configurable :tasks do
      setting :prelaunch, []
    end

    include Support::Definable
    include Support::Hookable
    include Support::Pipeline

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
    include Behavior::Operations
    include Behavior::Pipeline
    include Behavior::Rescuing
    include Behavior::Restarting

    attr_reader :parent

    def initialize(parent, &block)
      super()

      @parent = parent
      @state = []
      @endpoints = Endpoints.new

      performing :configure do
        configure!(@parent.environment)
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

      load_endpoints
      create_helper_contexts

      if respond_to?(:boot)
        boot
      end
    end

    def call(connection)
      instance = isolated(:Connection).allocate

      connection.instance_variables.each do |ivar|
        instance.instance_variable_set(ivar, connection.instance_variable_get(ivar))
      end

      instance.instance_variable_set(:@app, self)

      super(instance)
    end

    def method_missing(method_name, *args, &block)
      if @parent.respond_to?(method_name)
        @parent.public_send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @parent.respond_to?(method_name) || super
    end

    def helpers(connection)
      @helper_class.new(self, connection)
    end

    def __object_name
      self.class.__object_name
    end

    def plugin_path
      self.class.plugin_path
    end

    def helper_caller(helper_context, connection, call_context)
      HelperCaller.new(
        plugin: self,
        connection: connection,
        helpers: @helper_contexts[helper_context.to_sym].new(connection, call_context)
      )
    end

    def load_frontend
      @state.each(&:load_frontend)
    end

    def _dump(_)
      Marshal.dump(
        {
          parent: {
            name: @parent.config.name
          },

          plugin_name: self.class.plugin_name,
          plugin_path: self.class.plugin_path,
          mount_path: self.class.mount_path
        }
      )
    end

    def self._load(state)
      state = Marshal.load(state)
      Pakyow.app(state[:parent][:name]).plugs.find { |plug|
        plug.class.plugin_name == state[:plugin_name] &&
          plug.class.plugin_path == state[:plugin_path] &&
          plug.class.mount_path == state[:mount_path]
      }
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

    def load_endpoints
      state.each_with_object(@endpoints) do |(_, state_object), endpoints|
        state_object.instances.each do |state_instance|
          endpoints.load(state_instance)
        end
      end

      define_app_endpoints
    end

    def define_app_endpoints
      @endpoints.each do |endpoint|
        @parent.endpoints << Endpoint.new(
          name: [config.name.to_s, endpoint.name].join("_"),
          method: :get,
          builder: endpoint.builder
        )
      end
    end

    def create_helper_contexts
      @helper_contexts = %i(global passive active).each_with_object({}) { |context, helper_contexts|
        helper_class = Class.new do
          def initialize(connection, context)
            @connection, @context = connection, context
          end

          def method_missing(method_name, *args, &block)
            if @context.respond_to?(method_name)
              @context.public_send(method_name, *args, &block)
            else
              super
            end
          end

          def respond_to_missing?(method_name, include_private = false)
            @context.respond_to?(method_name, include_private) || super
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
