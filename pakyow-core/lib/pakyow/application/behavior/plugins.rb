# frozen_string_literal: true

require "pakyow/errors"

require "pakyow/support/deep_dup"
require "pakyow/support/extension"

require_relative "../../plugin/lookup"

module Pakyow
  class Application
    module Behavior
      # @api private
      module Plugins
        extend Support::Extension

        using Support::DeepDup

        attr_reader :plugs

        def plug(name, instance = :default)
          @plugs.find { |plug|
            plug.class.plugin_name == name && plug.class.object_name.namespace.parts.last == instance
          }
        end

        apply_extension do
          class_state :__plugs, default: [], inheritable: true

          # Create a dynamic helper that allows plugin helpers to be called in context of a specific plug.
          #
          on "setup" do
            register_helper :passive, Module.new {
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

          after "setup" do
            __plugs.each do |plug|
              if includes_framework?(:presenter)
                require "pakyow/plugin/helpers/presenter/rendering"
                plug.register_helper :passive, Plugin::Helpers::Presenter::Rendering
              end

              # Include frameworks from app.
              #
              plug.include_frameworks(
                *config.loaded_frameworks
              )

              # Create a dynamic helper that allows plugin helpers to be called in context of a specific plug.
              #
              plug.register_helper :passive, Module.new {
                Pakyow.plugins.keys.map.each do |plugin_name|
                  define_method plugin_name do |instance_name = :default|
                    app.top.plugs.send(plugin_name, instance_name).helper_caller(
                      app.class.included_helper_context(self),
                      @connection,
                      self
                    )
                  end
                end
              }

              plug.setup
            end
          end

          after "initialize", "initialize.plugins" do
            @plugs = Plugin::Lookup.new([])

            self.class.__plugs.each do |plug|
              plug_instance = plug.new(self)

              # Register the plug as an action in the app's pipeline.
              #
              top.action(plug_instance)

              # Finally, create the plugin instance.
              #
              @plugs << plug_instance
            end

            @plugs.finalize
          end

          after "boot" do
            @plugs.each(&:booted)
          end
        end

        class_methods do
          def plug(plugin_name, at: "/", as: :default, &block)
            plugin_name = plugin_name.to_sym

            unless (plugin = Pakyow.plugins[plugin_name])
              raise UnknownPlugin.new_with_message(
                plugin: plugin_name
              )
            end

            plug = plugin.make(*object_name.namespace.parts, plugin_name, as, "plug", mount_path: at, parent: self)
            plug.isolate(isolated(:Connection))
            plug.class_eval(&block) if block

            @__plugs << plug
          end
        end
      end
    end
  end
end
