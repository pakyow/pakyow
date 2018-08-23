# frozen_string_literal: true

require "pakyow/support/hookable"
require "pakyow/support/pipelined"
require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/security/helpers/csrf"

require "pakyow/presenter/renderer/actions/cleanup_prototype_nodes"
require "pakyow/presenter/renderer/actions/create_template_nodes"
require "pakyow/presenter/renderer/actions/embed_authenticity_token"
require "pakyow/presenter/renderer/actions/insert_prototype_bar"
require "pakyow/presenter/renderer/actions/install_endpoints"
require "pakyow/presenter/renderer/actions/place_in_mode"
require "pakyow/presenter/renderer/actions/setup_forms"

module Pakyow
  module Presenter
    class Renderer
      class << self
        def perform_for_connection(connection)
          if implicitly_render?(connection)
            begin
              catch :halt do
                renderer = new(connection)
                renderer.perform

                connection.body = StringIO.new(
                  renderer.presenter.to_html(clean_bindings: !Pakyow.env?(:prototype))
                )

                connection.rendered
              end
            rescue UnknownPage => error
              implicit_error = ImplicitRenderingError.build(error, context: connection.path)
              connection.set(:pw_error, implicit_error)
              connection.status = 404

              catch :halt do
                if Pakyow.env?(:production)
                  connection.app.subclass(:Controller).new(connection).trigger(404)
                else
                  renderer = new(connection, templates_path: "/development/500")
                  renderer.perform

                  connection.body = StringIO.new(
                    renderer.presenter.to_html(clean_bindings: !Pakyow.env?(:prototype))
                  )

                  connection.rendered
                end
              end
            rescue StandardError => error
              connection.logger.houston(error)

              if connection.app.class.includes_framework?(:core)
                catch :halt do
                  connection.app.subclass(:Controller).new(connection).handle_error(error)
                end
              end
            end
          end
        end

        def implicitly_render?(connection)
          connection.status == 200 && connection.method == :get && connection.format == :html &&
          (Pakyow.env?(:prototype) || ((!connection.halted? || connection.set?(:__fully_dispatched)) && !connection.rendered?))
        end

        def restore(connection, serialized)
          new(connection, **serialized)
        end
      end

      include Security::Helpers::CSRF

      include Support::Hookable
      known_events :render

      include Support::Pipelined
      include Support::Pipelined::Haltable

      action Actions::InstallEndpoints
      action Actions::InsertPrototypeBar
      action Actions::CleanupPrototypeNodes
      action Actions::CreateTemplateNodes
      action Actions::PlaceInMode
      action Actions::EmbedAuthenticityToken
      action Actions::SetupForms

      using Support::Refinements::Array::Ensurable
      using Support::Refinements::String::Normalization

      attr_reader :connection, :presenter, :mode

      def initialize(connection, templates_path: nil, presenter_path: nil, layout: nil, mode: :default, embed_templates: true)
        @connection, @embed_templates = connection, embed_templates

        @templates_path = String.normalize_path(templates_path || @connection.env["pakyow.endpoint"] || @connection.path)
        @presenter_path = presenter_path ? String.normalize_path(presenter_path) : nil
        @layout = layout

        @mode = if rendering_prototype?
          @connection.params[:mode] || :default
        else
          mode
        end

        unless info = find_info(@templates_path)
          error = UnknownPage.new("No view at path `#{@templates_path}'")
          error.context = @templates_path
          raise error
        end

        # Finds a matching layout across template stores.
        #
        if @layout && layout_object = layout_with_name(@layout)
          info[:layout] = layout_object.dup
        end

        info[:layout].mixin(info[:partials])
        info[:page].mixin(info[:partials])

        @presenter = (find_presenter(@presenter_path || @templates_path) || Presenter).new(
          info[:layout].build(info[:page]),
          binders: @connection.app.state(:binder),
          presentables: @connection.values,
          logger: @connection.logger
        )
      end

      def perform
        call(self)

        performing :render do
          @presenter.call
        end
      end

      def serialize
        {
          templates_path: @templates_path,
          presenter_path: @presenter_path,
          layout: @layout,
          mode: @mode
        }
      end

      def embed_templates?
        @embed_templates == true
      end

      def rendering_prototype?
        Pakyow.env?(:prototype)
      end

      private

      def find_info(path)
        collapse_path(path) do |collapsed_path|
          if info = info_for_path(collapsed_path)
            return info
          end
        end
      end

      def find_presenter(path)
        unless rendering_prototype?
          collapse_path(path) do |collapsed_path|
            if presenter = presenter_for_path(collapsed_path)
              return presenter
            end
          end
        end

        nil
      end

      def info_for_path(path)
        @connection.app.state(:templates).lazy.map { |store|
          store.info(path)
        }.find(&:itself)
      end

      def layout_with_name(name)
        @connection.app.state(:templates).lazy.map { |store|
          store.layout(name)
        }.find(&:itself)
      end

      def presenter_for_path(path)
        @connection.app.state(:presenter).find { |presenter|
          presenter.path == path
        }
      end

      def collapse_path(path)
        yield path; return if path == "/"

        yield path.split("/").keep_if { |part|
          part[0] != ":"
        }.join("/")

        nil
      end
    end
  end
end
