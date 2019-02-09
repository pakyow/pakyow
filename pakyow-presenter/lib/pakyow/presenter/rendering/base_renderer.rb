# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/hookable"
require "pakyow/support/pipeline"

module Pakyow
  module Presenter
    class BaseRenderer
      extend Support::ClassState
      class_state :__post_processors, default: []

      class << self
        def restore(connection, serialized)
          new(connection, **serialized)
        end

        def post_process(&block)
          @__post_processors << block
        end
      end

      include Support::Hookable
      events :render

      include Support::Pipeline
      include Support::Pipeline::Object

      action :dispatch

      attr_reader :connection, :presenter

      def initialize(connection, presenter)
        @connection, @presenter = connection, presenter
      end

      def perform
        call(self)
      end

      def serialize
        raise "serialize is not implemented on #{self}"
      end

      def rendering_prototype?
        Pakyow.env?(:prototype)
      end

      def to_html(clean_bindings: true, clean_versions: true)
        post_process(@presenter.to_html(clean_bindings: clean_bindings, clean_versions: clean_versions))
      end
      alias to_s to_html

      private

      def post_process(html)
        self.class.__post_processors.each do |post_processor|
          html = instance_exec(html, &post_processor)
        end

        html
      end

      def dispatch
        performing :render do
          @presenter.call
        end
      end

      # TODO: we should build this after booting and build a lookup on the app
      #
      def find_presenter(path = nil)
        unless path.nil? || Pakyow.env?(:prototype)
          Templates.collapse_path(path) do |collapsed_path|
            if presenter = presenter_for_path(collapsed_path)
              return presenter
            end
          end
        end

        @connection.app.isolated(:Presenter)
      end

      private

      def presenter_for_path(path)
        @connection.app.state(:presenter).find { |presenter|
          presenter.path == path
        }
      end
    end
  end
end
