# frozen_string_literal: true

require "pakyow/support/hookable"

module Pakyow
  module Presenter
    module RenderHelpers
      def render(path = request.env["pakyow.endpoint"] || request.path, as: nil, layout: nil)
        path = String.normalize_path(path)

        if as
          as = String.normalize_path(as)
        end

        app.class.const_get(:Renderer).new(@__state).perform(path, as: as, layout: layout); throw :halt
      end
    end

    class Renderer
      class << self
        def call(state)
          if auto_render?(state.request)
            # rubocop:disable Lint/HandleExceptions
            begin
              perform(state)
              state.processed
            rescue MissingView
              # TODO: in development, raise a missing view error in the case
              # of auto-render... so we can tell the user what to do
              #
              # in production, we want the auto_render to fail but ultimately lead
              # to a normal 404 error condition
            end
            # rubocop:enable Lint/HandleExceptions
          end
        end

        def handle_missing(_state); end

        def handle_failure(_state, _error); end

        def auto_render?(request)
          request.method == :get && request.format == :html
        end

        def perform(state)
          new(state).perform
        end
      end

      include Helpers

      include Support::Hookable
      known_events :render

      attr_reader :presenter

      def initialize(state)
        @__state = state
      end

      def setup(path = default_path, as: nil, layout: nil)
        unless info = find_info_for(path)
          raise MissingView.new("No view at path `#{path}'")
        end

        if layout && layout = layout_with_name(layout)
          info[:layout] = layout.dup
        end

        presenter = find_presenter_for(as || path) || ViewPresenter

        @presenter = presenter.new(
          binders: app.state_for(:binder),
          paths: app.paths,
          **info
        )
      end

      def perform(path = default_path, as: nil, layout: nil)
        setup(path, as: as, layout: layout)

        define_presentables(@__state.values)

        performing :render do
          response.body = StringIO.new(
            @presenter.to_html(
              clean: !Pakyow.env?(:prototype)
            )
          )
        end
      end

      protected

      def default_path
        request.env["pakyow.endpoint"] || request.path
      end

      def find_info_for(path)
        collapse_path(path) do |collapsed_path|
          if info = info_for_path(collapsed_path)
            return info
          end
        end
      end

      def find_presenter_for(path)
        return if Pakyow.env?(:prototype)

        collapse_path(path) do |collapsed_path|
          if presenter = presenter_for_path(collapsed_path)
            return presenter
          end
        end
      end

      def info_for_path(path)
        app.state_for(:templates).lazy.map { |store|
          store.info(path)
        }.find(&:itself)
      end

      def layout_with_name(name)
        app.state_for(:templates).lazy.map { |store|
          store.layout(name)
        }.find(&:itself)
      end

      def presenter_for_path(path)
        app.state_for(:view).find { |presenter|
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

      def define_presentables(presentables)
        presentables&.each do |name, value|
          @presenter.define_singleton_method name do
            value
          end
        end
      end
    end
  end
end
