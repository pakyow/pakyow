# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/makeable"

require_relative "../../composers/component"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module RenderComponents
          extend Support::Extension

          apply_extension do
            build do |view, app:, composer:, modes:|
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
                  component_view, app: app, composer: composer, modes: modes, path: initial_path
                )
              end
            end

            expose do |connection|
              # Expose the connection for performing from each component.
              #
              connection.set(:__component_connection, connection)
            end
          end

          # @api private
          def self.initialize_renderable_components(view, app:, composer:, modes:, path: [])
            view.components.each_with_index do |component_view, i|
              current_path = path.dup
              current_path << i

              # If view will be rendered from the app, look for the component on the app.
              #
              component_state = if app.is_a?(Plugin) && app.parent.view?(composer.view_path)
                app.parent.components.each.to_a
              else
                app.components.each.to_a
              end

              components = component_view.object.label(:components).each_with_object([]) { |component_label, arr|
                component_class = component_state.find { |component|
                  component.object_name.name == component_label[:name]
                }

                if component_class
                  # Turn the component into a renderable component. Once an instance is attached on the
                  # backend, the component will not be traversed by renders from its parent instead being
                  # rendered by its own renderer instance.
                  #
                  # We don't want the same restriction for non-renderable components because a change to
                  # the view should not affect how things work on the backend.
                  #
                  component_label[:renderable] = true

                  arr << {
                    class: component_class,
                    config: component_label[:config]
                  }
                end
              }

              if components.any?
                # Since one or more attached components is renderable, we no longer want to descend.
                #
                component_view.object.set_label(:descend, false)

                # Define the render function that calls the component and renders it at render time.
                #
                component_render = app.isolated(:Presenter).send(:render_proc, component_view) { |node, _context, string|
                  presentable_component_connection = presentables[:__component_connection]

                  component_connection = presentable_component_connection.class.from_connection(
                    presentable_component_connection,
                    :@values => presentable_component_connection.values.dup
                  )

                  components.each do |component|
                    # If the component was defined in an app but being called inside a plugin, set the app to the app instead of the plugin.
                    #
                    if component_connection.app.is_a?(Plugin) && component[:class].ancestors.include?(component_connection.app.parent.isolated(:Component))
                      component_connection = component_connection.class.from_connection(component_connection, :@app => component_connection.app.parent)
                    end

                    unless component[:class].inherit_values == true
                      component_connection.values.each_key do |key|
                        unless key.to_s.start_with?("__") || component[:class].inherit_values&.include?(key)
                          component_connection.values.delete(key)
                        end
                      end
                    end

                    component_instance = component[:class].new(
                      connection: component_connection,
                      config: component[:config]
                    )

                    # Call the component.
                    #
                    component_instance.perform
                  end

                  # Build a compound component presenter.
                  #
                  component_presenter = if components.length > 1
                    RenderComponents.find_compound_presenter(
                      app, components.map { |c| c[:class] }
                    )
                  else
                    components.first[:class].__presenter_class
                  end

                  # Setup the renderer for the component.
                  #
                  renderer = app.isolated(:Renderer).new(
                    app: app,
                    presentables: component_connection.values,
                    presenter_class: component_presenter,
                    composer: Composers::Component.new(
                      composer.view_path, current_path, app: app, labels: node.labels
                    ),
                    modes: modes
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
                  component_render.call(node, context, string)
                  nil
                end
              else
                initialize_renderable_components(
                  component_view, app: app, composer: composer, modes: modes, path: current_path
                )
              end
            end
          end

          # @api private
          def self.find_renderable_components(view, components = [])
            view.components.each do |component_view|
              find_renderable_components(component_view, components)

              if component_view.object.label(:components).any? { |c| c[:renderable] }
                components << component_view
              end
            end

            components
          end

          # @api private
          def self.wrap_block(block, context_class)
            proc do
              @app.presenter_for_context(
                context_class.__presenter_class, self
              ).instance_eval(&block)
            end
          end

          # @api private
          def self.find_compound_presenter(app, component_classes)
            compound_name = component_classes.map { |component_class|
              component_class.object_name.name.to_s
            }.join("_")

            object_name = Support::ObjectName.build(
              app.class.object_name.namespace.parts[0], :components, compound_name, :presenter
            )

            if const_defined?(object_name.constant)
              const_get(object_name.constant)
            end
          end

          # @api private
          #
          def self.find_or_build_compound_presenter(app, component_classes)
            compound_name = component_classes.map { |component_class|
              component_class.object_name.name.to_s
            }.join("_")

            object_name = Support::ObjectName.build(
              app.object_name.namespace.parts[0], :components, compound_name, :presenter
            )

            if const_defined?(object_name.constant)
              const_get(object_name.constant)
            else
              component_presenter = app.isolate(
                Class.new(app.isolated(:Presenter)), as: object_name, context: Object
              )

              component_classes.each do |component_class|
                # Copy unique attached renders.
                #
                component_class.__presenter_class.__attached_renders.each_with_index do |attached_render, i|
                  component_presenter.__attached_renders.insert(i, {
                    binding_path: attached_render[:binding_path],
                    channel: attached_render[:channel],
                    node: attached_render[:node],
                    priority: attached_render[:priority],
                    block: wrap_block(attached_render[:block], component_class)
                  })
                end

                # Copy unique global options.
                #
                component_class.__presenter_class.__global_options.each do |form_binding, field_binding_values|
                  field_binding_values.each do |field_binding, field_binding_value|
                    component_presenter.options_for(
                      form_binding,
                      field_binding,
                      field_binding_value[:options],
                      &wrap_block(field_binding_value[:block], component_class)
                    )
                  end
                end

                # Copy unique presentation logic.
                #
                component_class.__presenter_class.__presentation_logic.each do |binding_name, logic_arr|
                  unless component_presenter.__presentation_logic.include?(binding_name)
                    component_presenter.__presentation_logic[binding_name] = []
                  end

                  logic_arr.each_with_index do |logic, i|
                    component_presenter.__presentation_logic[binding_name].insert(i, {
                      block: wrap_block(logic[:block], component_class),
                      channel: logic[:channel]
                    })
                  end
                end

                # Copy unique versioning logic.
                #
                component_class.__presenter_class.__versioning_logic.each do |binding_name, logic_arr|
                  unless component_presenter.__versioning_logic.include?(binding_name)
                    component_presenter.__versioning_logic[binding_name] = []
                  end

                  logic_arr.each_with_index do |logic, i|
                    component_presenter.__versioning_logic[binding_name].insert(i, {
                      block: wrap_block(logic[:block], component_class)
                    })
                  end
                end
              end

              component_presenter
            end
          end
        end
      end
    end
  end
end
