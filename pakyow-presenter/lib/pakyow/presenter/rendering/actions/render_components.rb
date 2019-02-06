# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class RenderComponents
        def call(renderer)
          unless Pakyow.env?(:prototype)
            render(
              renderer.presenter,
              renderer.connection,
              renderer.templates_path,
              renderer.layout,
              renderer.mode
            )
          end
        end

        private

        def render(presenter, connection, templates_path, layout, mode, path: [])
          presenter.components.each_with_index do |component_presenter, i|
            component_path = path.dup << i

            # If we rendered from the app, look for the component on the app.
            #
            component_state = if connection.app.is_a?(Plugin) && connection.app.app.view?(templates_path)
              connection.app.app.state(:component)
            else
              connection.app.state(:component)
            end

            found_component = component_state.find { |component|
              component.__object_name.name == component_presenter.view.object.label(:component)
            }

            if found_component
              # Prevent values from being exposed outside of a component.
              #
              original_values = connection.values
              connection.instance_variable_set(
                :@values,
                Support::IndifferentHash.new(
                  connection.values.to_h.select { |key| key.to_s.start_with?("__") }
                )
              )

              # If the component was defined in an app but being called inside a
              # plugin, set the app to the app instead of the plugin.
              #
              if connection.app.is_a?(Plugin) && found_component.ancestors.include?(connection.app.app.isolated(:Component))
                original_app = connection.app
                connection.instance_variable_set(:@app, connection.app.app)
              end

              component_instance = found_component.new(
                connection: connection
              )

              component_instance.perform

              connection.app.isolated(:ComponentRenderer).new(
                connection,
                component_presenter,
                name: found_component.__object_name.name,
                templates_path: templates_path,
                component_path: component_path,
                layout: layout,
                mode: mode
              ).perform

              # Set the connection's app back to the original value.
              #
              if original_app
                connection.instance_variable_set(:@app, original_app)
              end

              # Remove exposed values that aren't internal to the framework.
              #
              connection.values.each do |key, value|
                next unless key.to_s.start_with?("__")
                original_values[key] = value
              end

              connection.instance_variable_set(:@values, original_values)
            end

            render(
              component_presenter,
              connection,
              templates_path,
              layout,
              mode,
              path: component_path
            )
          end
        end
      end
    end
  end
end
