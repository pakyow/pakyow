# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/security/helpers/csrf"

require "pakyow/presenter/rendering/base_renderer"
require "pakyow/presenter/rendering/component_renderer"
require "pakyow/presenter/rendering/actions/cleanup_prototype_nodes"
require "pakyow/presenter/rendering/actions/create_template_nodes"
require "pakyow/presenter/rendering/actions/embed_form_metadata"
require "pakyow/presenter/rendering/actions/insert_prototype_bar"
require "pakyow/presenter/rendering/actions/install_endpoints"
require "pakyow/presenter/rendering/actions/place_in_mode"
require "pakyow/presenter/rendering/actions/render_components"
require "pakyow/presenter/rendering/actions/setup_form_metadata"
require "pakyow/presenter/rendering/actions/setup_form_objects"

module Pakyow
  module Presenter
    class ViewRenderer < BaseRenderer
      class << self
        def render(connection, **args)
          renderer = new(connection, **args)
          renderer.perform

          html = renderer.to_html(clean_bindings: !Pakyow.env?(:prototype))
          connection.set_response_header(Rack::CONTENT_LENGTH, html.bytesize)
          connection.set_response_header(Rack::CONTENT_TYPE, "text/html")
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
              raise ImplicitRenderingError.build(error, context: connection.env["pakyow.endpoint.path"] || connection.path)
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
          (Pakyow.env?(:prototype) || ((!connection.halted? || connection.set?(:__fully_dispatched)) && !connection.rendered?))
        end

        def restore(connection, serialized)
          new(connection, **serialized)
        end
      end

      action :install_endpoints, Actions::InstallEndpoints, before: :dispatch
      action :insert_prototype_bar, Actions::InsertPrototypeBar, before: :dispatch
      action :cleanup_prototype_nodes, Actions::CleanupPrototypeNodes, before: :dispatch
      action :create_template_nodes, Actions::CreateTemplateNodes, before: :dispatch
      action :place_in_mode, Actions::PlaceInMode, before: :dispatch
      action :setup_form_metadata, Actions::SetupFormMetadata, before: :dispatch
      action :render_components, Actions::RenderComponents, before: :dispatch
      action :setup_form_objects, Actions::SetupFormObjects, after: :dispatch
      action :embed_form_metadata, Actions::EmbedFormMetadata, after: :setup_form_objects

      using Support::Refinements::String::Normalization

      attr_reader :templates_path, :mode

      def initialize(connection, templates_path: nil, presenter_path: nil, mode: :default, embed_templates: true)
        @connection, @embed_templates = connection, embed_templates

        @templates_path = String.normalize_path(templates_path || @connection.env["pakyow.endpoint.path"] || @connection.path)
        @presenter_path = presenter_path ? String.normalize_path(presenter_path) : nil

        @mode = if rendering_prototype?
          @connection.params[:mode] || :default
        else
          mode
        end

        @presenter = (find_presenter(@presenter_path || @templates_path)).new(
          @connection.app.view(@templates_path),
          binders: @connection.app.state(:binder),
          presentables: @connection.values,
          logger: @connection.logger
        )

        super(@connection, @presenter)
      end

      def serialize
        {
          templates_path: @templates_path,
          presenter_path: @presenter_path,
          mode: @mode
        }
      end

      def embed_templates?
        @embed_templates == true
      end
    end
  end
end
