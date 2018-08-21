# frozen_string_literal: true

require "pakyow/support/hookable"
require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/security/helpers/csrf"

module Pakyow
  module Presenter
    class Renderer
      class << self
        def perform_for_connection(connection)
          if implicitly_render?(connection)
            begin
              catch :halt do
                new(connection).perform
              end
            rescue UnknownPage => error
              implicit_error = ImplicitRenderingError.build(error, context: connection.path)
              connection.set(:pw_error, implicit_error)
              connection.status = 404

              catch :halt do
                if Pakyow.env?(:production)
                  connection.app.subclass(:Controller).new(connection).trigger(404)
                else
                  new(connection, templates_path: "/development/500").perform
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
      end

      include Support::Hookable
      known_events :render

      using Support::Refinements::Array::Ensurable
      using Support::Refinements::String::Normalization

      attr_reader :connection, :presenter

      def initialize(connection, templates_path: nil, presenter_path: nil, layout: nil, mode: :default, embed_templates: true)
        @connection = connection

        @templates_path = String.normalize_path(templates_path || default_path)
        @presenter_path = presenter_path ? String.normalize_path(presenter_path) : nil
        @layout = layout
        @mode = mode

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

        @presenter.install_endpoints(
          endpoints_for_environment,
          current_endpoint: @connection.endpoint,
          setup_for_bindings: rendering_prototype?
        )

        if rendering_prototype?
          @mode = @connection.params[:mode] || :default
        end

        if rendering_prototype?
          @presenter.insert_prototype_bar(@mode)
        else
          @presenter.cleanup_prototype_nodes

          if embed_templates
            @presenter.create_template_nodes
          end
        end

        @presenter.place_in_mode(@mode)

        if @connection.app.config.presenter.embed_authenticity_token
          embed_authenticity_token
        end

        setup_forms
      end

      def perform
        performing :render do
          @connection.body = StringIO.new(
            @presenter.to_html(clean_bindings: !rendering_prototype?)
          )
        end

        @connection.rendered
      end

      protected

      def rendering_prototype?
        Pakyow.env?(:prototype)
      end

      # We still mark endpoints as active when running in the prototype environment, but we don't
      # want to replace anchor hrefs, form actions, etc with backend routes. This gives the designer
      # control over how the prototype behaves.
      #
      def endpoints_for_environment
        if rendering_prototype?
          Endpoints.new
        else
          @connection.app.endpoints
        end
      end

      def default_path
        @connection.env["pakyow.endpoint"] || @connection.path
      end

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

      include Security::Helpers::CSRF

      def embed_authenticity_token
        if head = @presenter.view.object.find_significant_nodes(:head)[0]
          # embed the authenticity token
          head.append("<meta name=\"pw-authenticity-token\" content=\"#{authenticity_client_id}:#{authenticity_digest(authenticity_client_id)}\">\n")

          # embed the parameter name the token should be submitted as
          head.append("<meta name=\"pw-authenticity-param\" content=\"#{@connection.app.config.security.csrf.param}\">\n")
        end
      end

      def setup_forms
        @presenter.forms.each do |form|
          form.embed_origin(@connection.fullpath)

          if @connection.app.config.presenter.embed_authenticity_token
            digest = Support::MessageVerifier.digest(
              form.id, key: authenticity_server_id
            )

            form.embed_authenticity_token("#{form.id}:#{digest}", param: @connection.app.config.security.csrf.param)
          end
        end
      end
    end
  end
end
