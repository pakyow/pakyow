# frozen_string_literal: true

require "pakyow/support/hookable"

module Pakyow
  module Presenter
    module RenderHelpers
      def render(path = request.env["pakyow.endpoint"] || request.path, as: nil, layout: nil)
        path = String.normalize_path(path)
        as = String.normalize_path(as) if as

        app.class.const_get(:Renderer).new(@connection).perform(path, as: as, layout: layout)
      end
    end

    class Renderer
      class << self
        def perform_for_connection(connection)
          if implicitly_render?(connection)
            # rubocop:disable Lint/HandleExceptions
            begin
              catch :halt do
                new(connection).perform
              end
            rescue MissingView
              # TODO: in development, raise a missing view error in the case
              # of auto-render... so we can tell the user what to do
              #
              # in production, we want the implicit render to fail but ultimately lead
              # to a normal 404 error condition
            end
            # rubocop:enable Lint/HandleExceptions
          end
        end

        def implicitly_render?(connection)
          !connection.rendered? &&
            connection.response.status == 200 &&
            connection.request.method == :get &&
            connection.request.format == :html
        end
      end

      include Support::Hookable
      known_events :render

      attr_reader :presenter

      def initialize(connection)
        @connection = connection
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
          binders: @connection.app.state_for(:binder),
          endpoints: @connection.app.endpoints,
          **info
        )
      end

      def perform(path = default_path, as: nil, layout: nil)
        setup(path, as: as, layout: layout)

        define_presentables(@connection.values)

        performing :render do
          @connection.body = StringIO.new(
            @presenter.to_html(
              clean: !Pakyow.env?(:prototype)
            )
          )
        end

        @connection.rendered
      end

      protected

      def default_path
        @connection.env["pakyow.endpoint"] || @connection.path
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
        @connection.app.state_for(:templates).lazy.map { |store|
          store.info(path)
        }.find(&:itself)
      end

      def layout_with_name(name)
        @connection.app.state_for(:templates).lazy.map { |store|
          store.layout(name)
        }.find(&:itself)
      end

      def presenter_for_path(path)
        @connection.app.state_for(:presenter).find { |presenter|
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
