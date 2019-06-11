# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/composers/component"

module Pakyow
  module Presenter
    module Actions
      module RenderComponents
        extend Support::Extension

        apply_extension do
          build do |view, app:, composer:, mode:|
            unless Pakyow.env?(:prototype)
              initial_path = case composer
              when Composers::Component
                composer.component_path
              else
                []
              end

              component_view = case composer
              when Composers::Component
                composer.class.follow_path(composer.component_path, view)
              else
                view
              end

              RenderComponents.initialize_renderable_components(
                component_view, app: app, composer: composer, mode: mode, path: initial_path
              )
            end
          end

          expose do |connection|
            # Prevent state from leaking from the component to the rest of the app.
            #
            component_connection = connection.dup

            # Don't share exposures from the app with the component.
            #
            # component_connection.values.delete_if do |key, _|
            #   !key.to_s.start_with?("__")
            # end

            connection.set(:__component_connection, component_connection)
          end
        end

        # @api private
        def self.initialize_renderable_components(view, app:, composer:, mode:, path: [])
          view.components.each_with_index do |component_view, i|
            current_path = path.dup
            current_path << i

            # If view will be rendered from the app, look for the component on the app.
            #
            component_state = if app.is_a?(Plugin) && app.app.view?(composer.view_path)
              app.app.state(:component)
            else
              app.state(:component)
            end

            component_class = component_state.find { |component|
              component.__object_name.name == component_view.object.label(:component)
            }

            if component_class
              # Turn the component into a renderable component. Once an instance is attached on the
              # backend, the component will not be traversed by renders from its parent instead being
              # rendered by its own renderer instance.
              #
              # We don't want the same restriction for non-renderable components because a change to
              # the view should not affect how things work on the backend.
              #
              component_view.object.instance_variable_get(:@significance) << :renderable_component
              component_view.object.set_label(:descend, false)

              # Define the render function that calls the component and renders it at render time.
              #
              component_render = component_class.__presenter_class.send(:render_proc, component_view) { |_node, _context, string|
                presentable_component_connection = presentables[:__component_connection]
                component_connection = presentable_component_connection.dup

                presentables.each do |key, value|
                  if key.to_s.start_with?("__")
                    component_connection.set(key, value)
                  end
                end

                # If the component was defined in an app but being called inside a plugin, set the app to the app instead of the plugin.
                #
                if component_connection.app.is_a?(Plugin) && component_class.ancestors.include?(component_connection.app.app.isolated(:Component))
                  component_connection.instance_variable_set(:@app, component_connection.app.app)
                end

                component_instance = component_class.new(
                  connection: component_connection
                )

                # Call the component.
                #
                component_instance.perform

                # Setup the renderer for the component.
                #
                renderer = app.isolated(:Renderer).new(
                  app: app,
                  presentables: component_connection.values,
                  presenter_class: component_instance.class.__presenter_class,
                  composer: Composers::Component.new(composer.view_path, current_path),
                  mode: mode
                )

                # Render to the main buffer.
                #
                renderer.perform(string)

                # Return nil so nothing else gets written.
                #
                nil
              }

              # Attach the above render function to the render node.
              #
              component_view.object.transform do |node, context, string|
                component_render.call(node, context, string); nil
              end
            else
              initialize_renderable_components(
                component_view, app: app, composer: composer, mode: mode, path: current_path
              )
            end
          end
        end

        # @api private
        def self.find_renderable_components(view, components = [])
          view.components.each do |component_view|
            find_renderable_components(component_view, components)

            if component_view.object.significant?(:renderable_component)
              components << component_view
            end
          end

          components
        end
      end
    end
  end
end
