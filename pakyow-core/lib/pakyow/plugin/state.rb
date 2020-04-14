# frozen_string_literal: true

require_relative "../loader"

module Pakyow
  class Plugin
    # @api private
    class State
      def initialize(plugin, path: plugin.plugin_path)
        @plugin, @path = plugin, path
      end

      def backend_path(aspect)
        File.join(@path, "backend", aspect.to_s)
      end

      def frontend_path
        File.join(@path, "frontend")
      end

      def load_frontend
        @plugin.templates << Presenter::Templates.new(
          @plugin.config.name,
          frontend_path,
          processor: Presenter::ProcessorCaller.new(
            @plugin.parent.processors.each.map { |processor|
              processor.new(@plugin.parent)
            }
          )
        ).tap do |plugin_templates|
          if app_templates = @plugin.parent.templates.each.find { |templates| templates.name == :default }
            plugin_templates.paths.each do |path|
              plugin_info = plugin_templates.info(path)

              # Use the app's layout, if available.
              #
              if app_templates.layouts.include?(plugin_info[:page].info(:layout))
                plugin_info[:layout] = app_templates.layout(plugin_info[:page].info(:layout).to_sym)
                plugin_info[:partials].merge!(app_templates.includes)
              end

              if app_info = app_templates.info(File.join(@plugin.mount_path, path))
                # Define the plugin view as the `plug` partial so that it can be included.
                #
                plugin_info[:partials][:plug] = Presenter::Views::Partial.from_object(
                  :plug, plugin_info[:page].object
                )

                # Set the layout for the page.
                #
                plugin_info[:layout] = app_templates.layout(app_info[:page].info(:layout).to_sym)

                # Include the app partials, since we're using a page from the app that might include them.
                #
                plugin_info[:partials].merge!(app_info[:partials])

                # Finally, override the page with the one from the app.
                #
                plugin_info[:page] = app_info[:page]
              end
            end
          end
        end
      end
    end
  end
end
