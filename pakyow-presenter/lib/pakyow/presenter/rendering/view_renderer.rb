# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/security/helpers/csrf"

require "pakyow/presenter/rendering/base_renderer"
require "pakyow/presenter/rendering/pipeline"

module Pakyow
  module Presenter
    class ViewRenderer < BaseRenderer
      class << self
        def render(connection, **args)
          renderer = new(connection, **args)
          renderer.perform

          html = renderer.to_html(clean_bindings: !Pakyow.env?(:prototype))
          connection.set_header("content-type", "text/html")
          connection.body = StringIO.new(html)
          connection.rendered
        end

        def perform_for_connection(connection)
          if implicitly_render?(connection)
            begin
              catch :halt do
                render(connection)
              end
            rescue UnknownPage => error
              raise ImplicitRenderingError.build(error, context: connection.get(:__endpoint_path) || connection.path)
            end
          end
        rescue StandardError => error
          connection.logger.houston(error)

          if connection.app.class.includes_framework?(:routing)
            catch :halt do
              connection.app.controller_for_connection(connection).handle_error(error)
            end
          end
        end

        IMPLICIT_HTTP_METHODS = %i(get head).freeze

        def implicitly_render?(connection)
          IMPLICIT_HTTP_METHODS.include?(connection.method) && connection.format == :html &&
          (Pakyow.env?(:prototype) || ((!connection.halted?) && !connection.rendered?))
        end

        def restore(connection, serialized)
          new(connection, **serialized)
        end
      end

      include_pipeline Rendering::Pipeline

      using Support::Refinements::String::Normalization

      attr_reader :templates_path, :mode

      def initialize(connection, templates_path: nil, presenter_path: nil, mode: :default, embed_templates: true)
        @connection, @embed_templates = connection, embed_templates

        @templates_path = String.normalize_path(templates_path || @connection.get(:__endpoint_path) || @connection.path)
        @presenter_path = presenter_path ? String.normalize_path(presenter_path) : nil

        @mode = if rendering_prototype?
          @connection.params[:mode] || :default
        else
          mode
        end

        super(@connection, nil)
      end

      def perform
        @presenter = find_presenter.new(
          @connection.app.view(@templates_path),
          binders: @connection.app.state(:binder),
          presentables: @connection.values,
          logger: @connection.logger
        )

        super
      end

      def serialize
        {
          templates_path: @templates_path,
          presenter_path: @presenter_path,
          mode: @mode
        }
      end

      def find_presenter
        super(@presenter_path || @templates_path)
      end
    end
  end
end
