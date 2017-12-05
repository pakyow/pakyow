# frozen_string_literal: true

require "pakyow/support/hookable"

module Pakyow
  module Presenter
    module RenderHelpers
      def render(path = request.env["pakyow.endpoint"] || request.path, as: nil)
        Renderer.new(@__state).render(path, as: as); throw :halt
      end
    end

    class Renderer
      include Helpers

      include Support::Hookable
      known_events :render

      def self.perform(state)
        new(state).render
      end

      def initialize(state)
        @__state = state
      end

      def render(path = request.env["pakyow.endpoint"] || request.path, as: nil)
        unless info = find_info_for(path)
          raise MissingView.new("No view at path `#{path}'")
        end

        presenter = find_presenter_for(as || path) || ViewPresenter

        @current_presenter = presenter.new(
          binders: app.state_for(:binder),
          paths: app.paths,
          **info
        )

        define_presentables

        hook_around :render do
          response.body = StringIO.new(
            @current_presenter.to_html(
              clean: !Pakyow.env?(:prototype)
            )
          )
        end
      end

      protected

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
        app.state_for(:template_store).lazy.map { |store|
          store.info(path)
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

      def define_presentables
        @__state.get(:presentables)&.each do |name, value|
          @current_presenter.define_singleton_method name do
            value
          end
        end
      end
    end
  end
end
