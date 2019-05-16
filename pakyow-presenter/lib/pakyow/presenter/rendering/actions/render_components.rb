# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module RenderComponents
        extend Support::Extension

        apply_extension do
          build do |view, app:, view_path:, mode:|
            if app.config.presenter.componentize
              view.object.each_significant_node(:form) do |form|
                form.instance_variable_get(:@significance) << :component
                form.attributes[:"data-ui"] = :form
                form.set_label(:component, :form)
              end

              if html = view.object.find_first_significant_node(:html)
                html.instance_variable_get(:@significance) << :component
                html.attributes[:"data-ui"] = :navigable
                html.set_label(:component, :navigable)
              end
            end

            unless Pakyow.env?(:prototype)
              RenderComponents.initialize_renderable_components(
                view, app: app, view_path: view_path, mode: mode
              )
            end
          end

          expose do |connection|
            # Prevent state from leaking from the component to the rest of the app.
            #
            component_connection = connection.dup

            # Don't share exposures from the app with the component.
            #
            component_connection.values.delete_if do |key, _|
              !key.to_s.start_with?("__")
            end

            connection.set(:__component_connection, component_connection)
          end
        end

        # @api private
        def self.initialize_renderable_components(view, app:, view_path:, mode:)
          view.components.each do |component_view|
            initialize_renderable_components(
              component_view, app: app, view_path: view_path, mode: mode
            )

            # If view will be rendered from the app, look for the component on the app.
            #
            component_state = if app.is_a?(Plugin) && app.app.view?(view_path)
              app.app.state(:component)
            else
              app.state(:component)
            end

            component_class = component_state.find { |component|
              component.__object_name.name == component_view.object.label(:component)
            }

            if component_class
              component_view.object.instance_variable_get(:@significance) << :renderable_component
              component_view.object.set_label(:descend, false)

              # component_view.object.set_label(:component_metadata, {
              #   # view_path: view_path,
              #   # # TODO: build up the component path (in context of all components not just renderable)
              #   # path: []
              # })

              working_component_view = component_view.dup
              component_class.__presenter_class.attach(working_component_view)
              component_doc = StringDoc.from_nodes([working_component_view.object])

              component_render = component_class.__presenter_class.send(:render_proc, component_view) do |string|
                presentable_component_connection = @presentables[:__component_connection]
                component_connection = presentable_component_connection.dup
                component_connection.set(:__component_connection, presentable_component_connection)

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

                # Create a component presenter with the component connection.
                #
                component_presenter = component_instance.class.__presenter_class.new(
                  working_component_view, app: @app, presentables: component_connection.values
                )

                # Render to the main buffer.
                #
                component_doc.to_html(string, context: component_presenter)

                # Return nil so nothing else gets written.
                #
                nil
              end

              component_view.object.transform do |node, context, string|
                component_render.call(node, context, string); nil
              end
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
