# frozen_string_literal: true

require "pakyow/presenter/rendering/base_renderer"
require "pakyow/presenter/rendering/actions/install_endpoints"

module Pakyow
  module Presenter
    class ComponentRenderer < BaseRenderer
      class << self
        def restore(connection, serialized)
          new(
            connection,
            **serialized
          )
        end
      end

      action Actions::InstallEndpoints

      attr_reader :mode

      def initialize(connection, presenter = nil, name:, templates_path:, component_path:, layout:, mode:)
        @connection, @presenter, @name, @templates_path, @component_path, @layout, @mode = connection, presenter, name, templates_path, component_path, layout, mode

        unless @presenter
          @presenter = find_presenter.new(
            connection.app.build_view(
              templates_path, layout: layout
            )
          )

          # Place the presenter in the correct mode, since this could affect which component is returned.
          #
          Actions::PlaceInMode.new({}).call(self)

          # Follow the path to find the correct component.
          #
          while step = component_path.shift
            @presenter = @presenter.components[step]
          end
        end

        @presenter.presentables.merge!(connection.values)

        component_class = connection.app.state(:component).find { |component|
          component.__class_name.name == name
        }

        if component_class.__presenter_extension
          @presenter.instance_eval(&component_class.__presenter_extension)

          # Rebind actions in case they were redefined above.
          #
          @presenter.instance_variable_get(:@__pipeline).instance_variable_get(:@stack).map! { |action|
            if action.is_a?(::Method) && action.receiver.is_a?(Presenter)
              @presenter.method(action.name)
            else
              action
            end
          }
        end

        super(connection, @presenter)
      end

      def serialize
        {
          name: @name,
          templates_path: @templates_path,
          component_path: @component_path,
          layout: @layout,
          mode: @mode
        }
      end
    end
  end
end
