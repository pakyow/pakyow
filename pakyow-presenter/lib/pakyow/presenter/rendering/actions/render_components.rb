# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class RenderComponents
        def initialize(_options)
        end

        def call(renderer)
          render(
            renderer.presenter,
            renderer.connection,
            renderer.templates_path,
            renderer.layout,
            renderer.mode
          )
        end

        private

        def render(presenter, connection, templates_path, layout, mode, path: [])
          presenter.components.each_with_index do |component_presenter, i|
            component_path = path.dup << i

            found_component = connection.app.state(:component).find { |component|
              component.__object_name.name == component_presenter.view.object.label(:component)
            }

            if found_component
              original_values = connection.values
              connection.instance_variable_set(
                :@values,
                Support::IndifferentHash.new(
                  connection.values.to_h.select { |key| key.to_s.start_with?("__") }
                )
              )

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
