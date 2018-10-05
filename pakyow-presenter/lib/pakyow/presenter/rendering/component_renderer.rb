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
        @connection, @name, @templates_path, @component_path, @layout, @mode = connection, name, templates_path, component_path, layout, mode

        if presenter
          @presenter = find_presenter.new(presenter.view)
        else
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

      private

      def find_presenter
        component_class.__presenter_class
      end

      def component_class
        @connection.app.state(:component).find { |component|
          component.__object_name.name == @name
        }
      end
    end
  end
end
