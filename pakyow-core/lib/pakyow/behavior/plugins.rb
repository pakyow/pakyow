# frozen_string_literal: true

require "pakyow/errors"

require "pakyow/support/deep_dup"
require "pakyow/support/extension"

require "pakyow/plugin/lookup"

module Pakyow
  module Behavior
    module Plugins
      extend Support::Extension

      using Support::DeepDup

      attr_reader :plugs

      apply_extension do
        class_state :__plugs, default: [], inheritable: true

        # Create a dynamic helper that allows plugin helpers to be called in context of a specific plug.
        #
        on "initialize" do
          self.class.register_helper :passive, Module.new {
            Pakyow.plugins.keys.map.each do |plugin_name|
              define_method plugin_name do |plug = :default|
                app.plugs.send(plugin_name, plug).helper_caller(
                  app.class.included_helper_context(self),
                  @connection,
                  self
                )
              end
            end
          }
        end

        # Setting priority to low gives the app a chance to do any pre-loading
        # that might affect how plugins are setup.
        #
        on "load", "load.plugins", priority: :low do
          @__plug_instances = self.class.__plugs.map { |plug|
            if self.class.includes_framework?(:presenter)
              require "pakyow/plugin/helpers/rendering"
              plug.register_helper :passive, Plugin::Helpers::Rendering
            end

            # Include frameworks from app.
            #
            plug.include_frameworks(
              *self.class.config.loaded_frameworks
            )

            # Copy settings from the app config.
            #
            plug.config.instance_variable_set(
              :@__settings, config.__settings.deep_dup.merge(plug.config.__settings)
            )

            # Copy defaults from the app config.
            #
            plug.config.instance_variable_set(
              :@__defaults, config.__defaults.deep_dup.merge(plug.config.__defaults)
            )

            # Copy groups from the app config.
            #
            plug.config.instance_variable_set(
              :@__groups, config.__groups.deep_dup.merge(plug.config.__groups)
            )

            # Override config values that require a specific value.
            #
            full_name = [plug.plugin_name]
            unless plug.__object_name.name == :default
              full_name << plug.__object_name.name
            end

            plug.config.name = full_name.join("_").to_sym

            # Finally, create the plugin instance.
            #
            plug.new(self)
          }

          @plugs = Plugin::Lookup.new(@__plug_instances)
        end
      end

      class_methods do
        attr_reader :__plugs

        def plug(plugin_name, at: "/", as: :default, &block)
          plugin_name = plugin_name.to_sym

          unless plugin = Pakyow.plugins[plugin_name]
            raise UnknownPlugin.new_with_message(
              plugin: plugin_name
            )
          end

          app = self
          plug = plugin.make(
            as,
            within: Support::ObjectNamespace.new(
              *__object_name.namespace.parts + [plugin_name]
            ),
            mount_path: at,
          ) do
            # Creates a connection subclass that other frameworks can safely extend.
            #
            isolate(app.isolated(:Connection))

            instance_exec(&block) if block
          end

          @__plugs << plug
        end
      end
    end
  end
end
