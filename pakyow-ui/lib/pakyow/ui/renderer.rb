# frozen_string_literal: true

require "pakyow/presenter/renderer"

require "pakyow/ui/presenter"

module Pakyow
  module UI
    class Renderer < Pakyow::Presenter::Renderer
      attr_reader :app

      def initialize(app, presentables)
        @app, @presentables = app, presentables

        connection = Connection.new(@app, {})
        connection.instance_variable_set(:@values, @presentables)
        super(connection)
      end

      def perform(path)
        @presenter = Presenter.new
        define_presentables(@presentables)
        @presenter.instance_exec(&presenter_for_path(path).block)
      end

      def to_arr
        @presenter.to_arr
      end
    end
  end
end
