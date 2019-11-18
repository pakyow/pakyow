# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/hookable"

require "pakyow/support/core_refinements/proc/introspection"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/renderer/behavior/render_components"

require "pakyow/presenter/composers/view"

module Pakyow
  module Presenter
    class Renderer
      using Support::DeepFreeze

      extend Support::ClassState
      class_state :__presenter_views, default: {}, inheritable: true
      class_state :__presenters_by_path, default: {}, inheritable: true
      class_state :__build_fns, default: [], inheritable: true
      class_state :__attach_fns, default: [], inheritable: true
      class_state :__expose_fns, default: [], inheritable: true

      include Support::Hookable
      events :render

      # @api private
      attr_reader :app, :presentables, :presenter

      def initialize(app:, presentables:, presenter_class:, composer:, modes: [:default])
        @app, @presentables, @presenter_class, @composer, @modes = app, presentables, presenter_class, composer, modes
        initialize_presenter
      end

      def perform(output = String.new)
        performing :render do
          @presenter.to_html(output)
        end
      end

      def marshal_dump
        {
          app: @app,
          presentables: @presentables.reject { |_, value|
            # Filter out the component connection that we expose for component rendering.
            #
            value.is_a?(@app.isolated(:Connection))
          },
          presenter_class: @presenter_class,
          composer: @composer,
          modes: @modes
        }
      end

      def marshal_load(state)
        deserialize(state)
        initialize_presenter
      end

      private

      def deserialize(state)
        state.each do |key, value|
          instance_variable_set(:"@#{key}", value)
        end
      end

      def initialize_presenter
        @presenter = @presenter_class.new(
          find_or_build_presenter_view(@app, @composer, @presenter_class, @modes),
          presentables: @presentables, app: @app
        )
      end

      def find_or_build_presenter_view(app, composer, presenter, modes)
        presenter_view_key = [composer.key, presenter, modes]

        unless presenter_view = self.class.__presenter_views[presenter_view_key]
          presenter_view = composer.view

          self.class.build!(presenter_view, app: app, modes: modes, composer: composer)

          if composer.respond_to?(:post_process)
            presenter_view = composer.post_process(presenter_view)
          end

          presenter.attach(presenter_view)
          presenter_view.object.finalize_labels(keep: [:form, :endpoint_params])
          presenter_view.deep_freeze

          self.class.__presenter_views[presenter_view_key] = presenter_view
        end

        if composer.respond_to?(:finalize)
          presenter_view = composer.finalize(presenter_view)
        end

        presenter_view
      end

      class << self
        using Support::Refinements::Proc::Introspection
        using Support::Refinements::String::Normalization

        def render(connection, view_path: nil, presenter_path: nil, modes: [:default])
          connection.app.__ui_modes.each do |mode, block|
            if block.call(connection)
              modes << mode
            end
          end

          view_path = if view_path
            String.normalize_path(view_path)
          else
            connection.get(:__endpoint_path) || connection.path
          end

          presenter_path = if presenter_path
            String.normalize_path(presenter_path)
          else
            view_path.dup
          end

          if connection.app.is_a?(Plugin) && connection.app.class.mount_path != "/"
            presenter_path.gsub!(/^#{connection.app.class.mount_path}/, "")
          end

          presenter = find_presenter(connection.app, presenter_path)

          expose!(connection)

          renderer = new(
            app: connection.app,
            presentables: connection.values,
            presenter_class: presenter,
            composer: Composers::View.new(view_path, app: connection.app),
            modes: modes
          )

          connection.set(:__view_path, view_path)
          connection.set_header("content-type", "text/html")

          if connection.app.config.presenter.features.streaming
            connection.stream do
              renderer.perform(connection.body)
            end
          else
            output = renderer.perform(StringIO.new); output.rewind
            connection.body = output
          end

          connection.rendered
        end

        # @api private
        def render_implicitly(connection)
          view_path = connection.get(:__endpoint_path) || connection.path

          if render_implicitly?(connection)
            begin
              catch :halt do
                render(connection, view_path: view_path)
              end
            rescue UnknownPage => error
              unless connection.app.is_a?(Plugin)
                raise ImplicitRenderingError.build(error, context: view_path)
              end
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

        # @api private
        def build!(view, app:, modes:, composer:)
          @__build_fns.each do |fn|
            options = {}

            if fn.keyword_argument?(:app)
              options[:app] = app
            end

            if fn.keyword_argument?(:modes)
              options[:modes] = modes
            end

            if fn.keyword_argument?(:composer)
              options[:composer] = composer
            end

            fn.call(view, **options)
          end
        end

        # @api private
        def attach!(presenter, app:)
          @__attach_fns.each do |fn|
            options = {}

            if fn.keyword_argument?(:app)
              options[:app] = app
            end

            fn.call(presenter, **options)
          end
        end

        # @api private
        def expose!(connection)
          @__expose_fns.each do |fn|
            fn.call(connection)
          end
        end

        # @api private
        def find_presenter(app, path)
          path = String.normalize_path(path)
          unless presenter = @__presenters_by_path[path]
            presenter = if path.nil? || Pakyow.env?(:prototype)
              app.isolated(:Presenter)
            else
              find_presenter_for_path(app, path)
            end

            @__presenters_by_path[path] = presenter
          end

          presenter
        end

        private

        def build(&block)
          @__build_fns << block
        end

        def attach(&block)
          @__attach_fns << block
        end

        def expose(&block)
          @__expose_fns << block
        end

        IMPLICIT_HTTP_METHODS = %i(get head).freeze
        IMPLICIT_HTTP_FORMATS = %i(any html).freeze

        def render_implicitly?(connection)
          IMPLICIT_HTTP_METHODS.include?(connection.method) && IMPLICIT_HTTP_FORMATS.include?(connection.format) &&
            (Pakyow.env?(:prototype) || ((!connection.halted?) && !connection.rendered?))
        end

        def find_presenter_for_path(app, path)
          presenter_for_path(app, String.collapse_path(path)) || app.isolated(:Presenter)
        end

        def presenter_for_path(app, path)
          app.state(:presenter).find { |presenter|
            presenter.path == path
          }
        end
      end
    end
  end
end
