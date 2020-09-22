# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/configurable"
require "pakyow/support/definable"
require "pakyow/support/handleable"
require "pakyow/support/hookable"
require "pakyow/support/makeable"
require "pakyow/support/pipeline"

require_relative "application/behavior/aspects"
require_relative "application/behavior/endpoints"
require_relative "application/behavior/frameworks"
require_relative "application/behavior/helpers"
require_relative "application/behavior/operations"
require_relative "application/behavior/rescuing"

require_relative "handleable/behavior/statuses"

require_relative "application"
require_relative "endpoints"

require_relative "plugin/helper_caller"

module Pakyow
  # Base plugin class.
  #
  # @api private
  class Plugin
    require_relative "plugin/state"

    extend Support::ClassState
    class_state :__enabled_features, default: []
    class_state :__disabled_features, default: []

    include Support::Configurable

    setting :name do
      if object_name
        if object_name.namespace.parts.any?
          parts = object_name.namespace.parts
          parts = parts[parts.index(plugin_name)..-1]
          parts.pop if parts.last == :default
          parts.join("_").to_sym
        else
          plugin_name
        end
      end
    end

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

      deprecate :prelaunch
    end

    include Support::Definable
    include Support::Handleable
    include Support::Hookable
    include Support::Makeable
    include Support::Pipeline

    # Use the same events as app.
    #
    events(*Application.events)

    # Include behavior so that plugin behaves like an app.
    #
    include Application::Behavior::Aspects
    include Application::Behavior::Endpoints
    include Application::Behavior::Frameworks
    include Application::Behavior::Helpers
    include Application::Behavior::Operations
    include Application::Behavior::Rescuing

    include Handleable::Behavior::Statuses

    attr_reader :parent

    class << self
      attr_reader :parent

      def setup(environment: Pakyow.env)
        performing :setup do
          performing :configure do
            configure!(environment)
          end

          performing :load do
            load_state
          end
        end
      end

      def feature?(name)
        name = name.to_sym
        features.any? { |feature|
          feature[:name] == name
        }
      end

      private def load_aspect(aspect, **)
        @state.each do |state|
          super(aspect, path: state.backend_path(aspect), target: self)
        end
      end

      private def load_state
        @state = []
        load_global_state
        load_feature_state
      end

      private def load_global_state
        @state << State.new(self)
      end

      private def load_feature_state
        features.each do |feature|
          @state << State.new(self, path: feature[:path])

          initializer = File.join(feature[:path], "initializer.rb")

          if File.exist?(initializer)
            class_eval(File.read(initializer), initializer)
          end
        end
      end

      private def load_frontend
        @state.each(&:load_frontend)
      end
    end

    def initialize(parent)
      @parent = parent
      @key = build_key

      performing :initialize do
        # Empty, but still need to perform initialize.
      end

      define_app_endpoints
      create_helper_contexts
    end

    def booted
      call_hooks :after, :boot
    end

    def feature?(name)
      self.class.feature?(name)
    end

    def call(connection)
      if connection.path.start_with?(mount_path)
        plugin_connection = isolated(:Connection).from_connection(connection, :@app => self)

        if plugin_connection.instance_variable_defined?(:@path)
          plugin_connection.remove_instance_variable(:@path)
        end

        super(plugin_connection)
      end
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

    # @api private
    def object_name
      self.class.object_name
    end

    def plugin_name
      self.class.plugin_name
    end

    def plugin_path
      self.class.plugin_path
    end

    def mount_path
      self.class.mount_path
    end

    def helper_caller(helper_context, connection, call_context)
      connection = connection.class.from_connection(connection, :@app => self)

      HelperCaller.new(
        plugin: self,
        connection: connection,
        helpers: @helper_contexts[helper_context.to_sym].new(connection, call_context)
      )
    end

    def exposed_value_name(name)
      prefix = if self.class.object_name.name == :default
        self.class.plugin_name
      else
        "#{self.class.plugin_name}(#{self.class.object_name.name})"
      end

      :"__#{prefix}.#{name}"
    end

    # @api private
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

    # @api private
    def self._load(state)
      state = Marshal.load(state)
      Pakyow.app(state[:parent][:name]).plugs.find { |plug|
        plug.class.plugin_name == state[:plugin_name] &&
          plug.class.plugin_path == state[:plugin_path] &&
          plug.class.mount_path == state[:mount_path]
      }
    end

    def frontend_key(name = nil)
      if name
        :"@#{@key}.#{name}"
      else
        @key
      end
    end

    def top
      parent.top
    end

    private

    def build_key
      namespace = self.class.object_name.namespace.parts.last

      case namespace
      when :default
        :"#{self.class.plugin_name}"
      else
        :"#{self.class.plugin_name}.#{namespace}"
      end
    end

    def define_app_endpoints
      @endpoints.each do |endpoint|
        # Register endpoints accessible for backend path building.
        #
        top.endpoints.build(
          name: [config.name.to_s, endpoint.name].join("_"),
          method: endpoint.method,
          builder: endpoint.builder,
          prefix: endpoint.prefix
        )

        # Register endpoints accessible for frontend path building.
        #
        namespace = self.class.object_name.namespace.parts.last

        endpoint_name = if namespace == :default
          :"@#{self.class.plugin_name}.#{endpoint.name}"
        else
          :"@#{self.class.plugin_name}(#{namespace}).#{endpoint.name}"
        end

        top.endpoints.build(
          name: endpoint_name,
          method: endpoint.method,
          builder: endpoint.builder,
          prefix: endpoint.prefix
        )
      end
    end

    def create_helper_contexts
      @helper_contexts = %i[global passive active].each_with_object({}) { |context, helper_contexts|
        helper_class = Class.new {
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
        }

        self.class.include_helpers(context, helper_class)
        helper_contexts[context] = helper_class
      }
    end

    class << self
      attr_reader :plugin_name, :plugin_path, :mount_path

      def Plugin(name, path)
        make name, plugin_name: name, plugin_path: path
      end

      def inherited(plugin_class)
        super

        if instance_variable_defined?(:@plugin_name)
          plugin_class.instance_variable_set(:@plugin_name, instance_variable_get(:@plugin_name))
          plugin_class.instance_variable_set(:@plugin_path, instance_variable_get(:@plugin_path))

          unless Pakyow.plugins.include?(@plugin_name)
            Pakyow.register_plugin(@plugin_name, plugin_class)
          end
        end
      end

      def enable(*features)
        @__enabled_features.concat(features)
      end

      def disable(*features)
        @__disabled_features.concat(features)
      end

      def features
        features = Dir.glob(File.join(plugin_path, "features", "*")).map { |feature_path|
          {
            name: File.basename(feature_path).to_sym,
            path: feature_path
          }
        }

        features.delete_if do |feature|
          @__disabled_features.include?(feature[:name])
        end

        if @__enabled_features.any?
          features.keep_if do |feature|
            @__enabled_features.include?(feature[:name])
          end
        end

        features
      end

      private def isolable_context
        object_name && object_name.namespace.parts.any? ? Kernel.const_get(object_name.namespace.constant) : self
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
