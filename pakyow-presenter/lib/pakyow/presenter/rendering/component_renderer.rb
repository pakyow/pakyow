# frozen_string_literal: true

require "pakyow/presenter/rendering/base_renderer"

require "pakyow/presenter/rendering/actions/place_in_mode"
require "pakyow/presenter/rendering/actions/install_endpoints"
require "pakyow/presenter/rendering/actions/setup_forms"

module Pakyow
  module Presenter
    class ComponentRenderer < BaseRenderer
      class << self
        def build_recursively(mode:, templates_path:, connection:, presenter:, path: [], renders: [])
          renders.tap do
            presenter.components.each.with_index do |component_presenter, i|
              component_path = path.dup << i

              renderer = ComponentRenderer.build(
                name: component_presenter.view.object.label(:component),
                path: component_path, mode: mode, presenter: component_presenter,
                connection: connection, templates_path: templates_path
              )

              if renderer
                renders << renderer
              else
                build_recursively(
                  mode: mode,
                  templates_path: templates_path,
                  connection: connection,
                  presenter: component_presenter,
                  path: component_path,
                  renders: renders
                )
              end
            end
          end
        end

        def build(name:, path:, mode:, connection:, templates_path:, presenter:)
          # If we rendered from the app, look for the component on the app.
          #
          component_state = if connection.app.is_a?(Plugin) && connection.app.app.view?(templates_path)
            connection.app.app.state(:component)
          else
            connection.app.state(:component)
          end

          found_component = component_state.find { |component|
            component.__object_name.name == name
          }

          if found_component
            # Prevent state from leaking from the component to the rest of the app.
            #
            component_connection = connection.dup

            # Don't share exposures from the app with the component.
            #
            component_connection.values.delete_if do |key, _|
              !key.to_s.start_with?("__")
            end

            # If the component was defined in an app but being called inside a plugin, set the app to the app instead of the plugin.
            #
            if component_connection.app.is_a?(Plugin) && found_component.ancestors.include?(component_connection.app.app.isolated(:Component))
              component_connection.instance_variable_set(:@app, component_connection.app.app)
            end

            component_instance = found_component.new(
              connection: component_connection
            )

            # Call the component.
            #
            component_instance.perform

            component_connection.app.isolated(:ComponentRenderer).new(
              component_connection, presenter,
              name: name,
              mode: mode,
              component_path: path,
              component_class: found_component,
              templates_path: templates_path
            )
          else
            nil
          end
        end

        def restore(connection, serialized, **options)
          new(connection, **serialized.merge(options))
        end
      end

      action :install_endpoints, Actions::InstallEndpoints, before: :dispatch
      action :setup_form_objects, Actions::SetupForms, before: :dispatch

      attr_reader :mode, :name, :component_path, :templates_path, :renders

      def initialize(connection, presenter = nil, name:, templates_path:, component_path:, component_class:, mode:, descend: true)
        @connection, @name, @templates_path, @component_path, @component_class, @mode, @descend = connection, name, templates_path, component_path, component_class, mode, descend
        super(connection, presenter)

        unless presenter
          @presenter = build_presenter
          Actions::PlaceInMode.new.call(self)
        end

        @renders = if @descend
          self.class.build_recursively(
            mode: @mode,
            templates_path: @templates_path,
            connection: @connection,
            presenter: @presenter,
            path: @component_path
          )
        else
          []
        end
      end

      def perform
        if @descend
          @renders.each(&:perform)
        end

        # When this isn't a custom component object, there's nothing to perform.
        #
        unless @component_class == @connection.app.isolated(:Component)
          @presenter = find_presenter.new(
            @presenter.view,
            binders: @connection.app.state(:binder),
            presentables: @connection.values,
            logger: @connection.logger
          )

          super
        end
      end

      def serialize
        {
          name: @name,
          templates_path: @templates_path,
          component_path: @component_path,
          component_class: @component_class,
          mode: @mode
        }
      end

      private

      def find_presenter
        @component_class.__presenter_class
      end

      def build_presenter
        object = connection.app.view(@templates_path, copy: false).object

        # Follow the path to find the correct component.
        #
        component_path = @component_path.dup
        while step = component_path.shift
          object = object.find_significant_nodes_without_descending(:component).reject { |node|
            node.labeled?(:mode) && node.label(:mode) != @mode
          }[step]
        end

        # Return a presenter wrapping a copy of the component object.
        #
        Presenter.new(View.from_object(object.dup))
      end
    end
  end
end
