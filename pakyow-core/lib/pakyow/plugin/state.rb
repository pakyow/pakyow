# frozen_string_literal: true

require "pakyow/loader"

module Pakyow
  class Plugin
    # @api private
    class State
      def initialize(plugin, path: plugin.class.plugin_path)
        @plugin, @path = plugin, path
      end

      def backend_path(aspect)
        File.join(@path, "backend", aspect.to_s)
      end

      def frontend_path
        File.join(@path, "frontend")
      end

      def load_frontend
        @plugin.state(:templates) << Presenter::Templates.new(
          @plugin.config.name,
          frontend_path,
          config: {
            prefix: @plugin.class.mount_path
          },
          processor: Presenter::ProcessorCaller.new(
            @plugin.app.state(:processor)
          )
        ).tap do |plugin_templates|
          if app_templates = @plugin.app.state(:templates).find { |templates| templates.name == :default }
            plugin_templates.paths.each do |path|
              plugin_info = plugin_templates.info(path)

              # Use the app's layout, if available.
              #
              if app_templates.layouts.include?(plugin_info[:page].info(:layout))
                plugin_info[:layout] = app_templates.layouts[plugin_info[:page].info(:layout)]
              end

              if app_info = app_templates.info(path)
                # Define the plugin view as the `plug` partial so that it can be included.
                #
                plugin_info[:partials][:plug] = Presenter::Partial.from_object(
                  :plug, plugin_info[:page].object
                )

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

        if error_templates = @plugin.app.state(:templates).find { |templates| templates.name == :errors }
          @plugin.state(:templates) << error_templates
        end
      end
    end
  end
end
