# frozen_string_literal: true

require "pakyow/presenter/renderer"

require "pakyow/ui/presenter"

module Pakyow
  module UI
    class Renderer < Pakyow::Presenter::Renderer
      attr_reader :app

      def initialize(app, presentables)
        @app, @presentables = app, presentables
      end

      def perform(path)
        @current_presenter = Presenter.new
        define_presentables(@presentables)
        @current_presenter.instance_exec(&presenter_for_path(path).block)
      end

      def to_arr
        @current_presenter.to_arr
      end
    end
  end
end
