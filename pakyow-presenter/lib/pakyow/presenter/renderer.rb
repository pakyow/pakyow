# frozen_string_literal: true

require "forwardable"

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/hookable"
require "pakyow/support/pipeline"

require "pakyow/support/core_refinements/proc/introspection"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/rendering/actions/render_components"

# view:
# def initialize(connection, templates_path: nil, presenter_path: nil, mode: :default, embed_templates: true)
#
# * templates_path
# * presenter_path

# component:
# def initialize(connection, presenter = nil, name:, templates_path:, component_path:, component_class:, mode:)
#
# * templates_path
# * component_path
# * component_class

# presenter_path, component_class can both go away in favor of passing the presenter class itself
#   as long as the internal class references don't change... which they shouldn't
#
# component_path instructs how to find the view

module Pakyow
  module Presenter
    class Renderer
      extend Forwardable
      def_delegators :@presenter, :to_html

      using Support::DeepDup
      using Support::DeepFreeze

      extend Support::ClassState
      class_state :__presenter_views, default: {}, inheritable: true
      class_state :__presenters_by_path, default: {}, inheritable: true
      class_state :__build_fns, default: [], inheritable: true
      class_state :__attach_fns, default: [], inheritable: true
      class_state :__expose_fns, default: [], inheritable: true

      extend Support::DeepFreeze
      unfreezable :__presenters_by_path, :__presenter_views

      include Support::Hookable
      events :render

      include Support::Pipeline
      include Support::Pipeline::Object

      # TODO: we want to move actions back here; each action's `call` method will deal with an instance
      # of the renderer for connection-time behavior; it can also define class methods for the following:
      #
      #   * attach: attaches renders to the passed presenter class
      #     (this will be the app's presenter, and will happen once at boot)
      #
      #   * build: makes changes to the view during the view building process
      #     (happens from the renderer when view is built)
      #
      # the renderer will cache raw views, and view with attached renders for a specific presenter
      # alternatively we can change presenter to be initialized with a view, where renders are attached
      # and then passed a connection and any other per-request state to `call` (which dups, sets state and renders)

      # TODO: where should components be rendered? we need the top-level connection object, so perhaps
      # we don't render them from the parent renderer... as that would require the connection (as well
      # as dealing with not rendering components when performing things like ui renders)
      #
      # related issue is regarding rendering the view as one, across multiple presenters
      #
      # since we need connection state to call the component this would happen from Renderer::render
      # at this point we have the presentables as well as the presenter class for each component
      #
      # next we need a mechanism to evaluate multiple presenters in the context of a single render
      # this is a challenge because we are rendering from multiple contexts (e.g. the main presenter
      # and the presenter for each component that contains its presentable state)
      #
      # almost like we need a concept of context for a node in stringdoc; so both the main presenter
      # and the component presenters refer to the same underlying node objects, and we describe context
      # from the main presenter as being the nested presenters setup during Render::render
      #
      # action :render_components, Actions::RenderComponents
      # action :dispatch

      def initialize(app:, presentables:, view_path:, presenter_class:, component_path: nil, mode: :default)
        @app, @presentables, @view_path, @presenter_class, @component_path, @mode = app, presentables, view_path, presenter_class, component_path, mode
        @presenter = build_presenter(app, presentables, view_path, presenter_class, component_path, mode)
      end

      def marshal_dump
        {
          app: @app.config.name,
          view_path: @view_path,
          presenter_class: @presenter_class,
          component_path: @component_path,
          mode: @mode
        }
      end

      def marshal_load(state)
        # TODO
      end

      private

      def dispatch
        performing :render do
          @presenter.call
        end
      end

      def build_presenter(app, presentables, view_path, presenter_class, component_path, mode)
        presenter_class.new(
          find_or_build_presenter_view(app, view_path, presenter_class, component_path, mode),
          presentables: presentables,
          app: app
        )
      end

      UNRETAINED_SIGNIFICANCE = %i(container partial template).freeze

      def find_or_build_presenter_view(app, view_path, presenter_class, component_path, mode)
        presenter_view_key = [view_path, presenter_class, component_path, mode]

        unless presenter_view = self.class.__presenter_views[presenter_view_key]
          unless info = app.find_view_info(view_path)
            error = UnknownPage.new("No view at path `#{view_path}'")
            error.context = view_path
            raise error
          end

          info = info.deep_dup
          presenter_view = info[:layout].build(info[:page]).tap { |view|
            view.mixin(info[:partials])
          }

          self.class.build!(presenter_view, app: app, mode: mode, view_path: view_path)

          # We collapse built views down to significance that is considered "renderable". This is
          # mostly an optimization, since it lets us collapse some nodes into single strings and
          # reduce the number of operations needed for a render.
          #
          presenter_view.object.collapse(
            *(StringDoc.significant_types.keys - UNRETAINED_SIGNIFICANCE)
          )

          # Empty nodes are removed as another render-time optimization leading to fewer operations.
          #
          presenter_view.object.remove_empty_nodes

          presenter_class.attach(presenter_view)
          presenter_view.deep_freeze

          self.class.__presenter_views[presenter_view_key] = presenter_view
        end

        presenter_view
      end

      class << self
        using Support::Refinements::Proc::Introspection
        using Support::Refinements::String::Normalization

        def render(connection, view_path: nil, presenter_path: nil, mode: :default)
          view_path = if view_path
            String.normalize_path(view_path)
          else
            connection.get(:__endpoint_path) || connection.path
          end

          presenter_path = if presenter_path
            String.normalize_path(presenter_path)
          else
            view_path
          end

          presenter_class = find_presenter(connection.app, presenter_path)

          expose!(connection)

          renderer = new(
            app: connection.app,
            presentables: connection.values,
            view_path: view_path,
            presenter_class: presenter_class,
            mode: mode
          )

          connection.set_header("content-type", "text/html")
          connection.stream { renderer.to_html(connection.body) }
          connection.rendered
        end

        # TODO: rename to `render_implicitly`
        #
        def perform(connection)
          view_path = connection.get(:__endpoint_path) || connection.path

          if implicitly_render?(connection)
            begin
              catch :halt do
                render(connection, view_path: view_path)
              end
            rescue UnknownPage => error
              raise ImplicitRenderingError.build(error, context: view_path)
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

        def build!(view, app:, mode:, view_path:)
          @__build_fns.each do |fn|
            options = {}

            if fn.keyword_argument?(:app)
              options[:app] = app
            end

            if fn.keyword_argument?(:mode)
              options[:mode] = mode
            end

            if fn.keyword_argument?(:view_path)
              options[:view_path] = view_path
            end

            fn.call(view, **options)
          end
        end

        def attach!(presenter, app:)
          @__attach_fns.each do |fn|
            options = {}

            if fn.keyword_argument?(:app)
              options[:app] = app
            end

            fn.call(presenter, **options)
          end
        end

        def expose!(connection)
          @__expose_fns.each do |fn|
            fn.call(connection)
          end
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

        # TODO: rename to `render_implicitly?`
        #
        def implicitly_render?(connection)
          IMPLICIT_HTTP_METHODS.include?(connection.method) && connection.format == :html &&
            (Pakyow.env?(:prototype) || ((!connection.halted?) && !connection.rendered?))
        end

        def find_presenter(app, path)
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

        def find_presenter_for_path(app, path)
          Templates.collapse_path(path) do |collapsed_path|
            if presenter = presenter_for_path(app, collapsed_path)
              return presenter
            end
          end

          app.isolated(:Presenter)
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
