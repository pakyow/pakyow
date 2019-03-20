# frozen_string_literal: true

require "pakyow/presenter/rendering/base_renderer"
require "pakyow/presenter/rendering/pipeline"

module Pakyow
  module Presenter
    class ComponentRenderer < BaseRenderer
      class << self
        def build(name:, path:, mode:, connection:, templates_path:, presenter:)
          component_class = presenter.view.object.label(:component_class)

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
          if component_connection.app.is_a?(Plugin) && component_class.ancestors.include?(component_connection.app.app.isolated(:Component))
            component_connection.instance_variable_set(:@app, component_connection.app.app)
          end

          component_instance = component_class.new(
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
            component_class: component_class,
            templates_path: templates_path
          )
        end

        def restore(connection, serialized, **options)
          new(connection, **serialized.merge(options))
        end
      end

      include_pipeline Rendering::Pipeline

      attr_reader :mode, :name, :component_path, :templates_path

      def initialize(connection, presenter = nil, name:, templates_path:, component_path:, component_class:, mode:)
        @connection, @name, @templates_path, @component_path, @component_class, @mode = connection, name, templates_path, component_path, component_class, mode
        super(connection, presenter || build_presenter)
      end

      def perform
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
