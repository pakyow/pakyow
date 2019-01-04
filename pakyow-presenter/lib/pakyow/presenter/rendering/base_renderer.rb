# frozen_string_literal: true

require "pakyow/support/hookable"
require "pakyow/support/pipelined"

module Pakyow
  module Presenter
    class BaseRenderer
      class << self
        def restore(connection, serialized)
          new(connection, **serialized)
        end
      end

      include Support::Hookable
      events :render

      include Support::Pipelined
      include Support::Pipelined::Object

      attr_reader :connection, :presenter

      def initialize(connection, presenter)
        @connection, @presenter = connection, presenter
      end

      def perform
        call(self)

        performing :render do
          @presenter.call
        end
      end

      def serialize
        raise "serialize is not implemented on #{self}"
      end

      def rendering_prototype?
        Pakyow.env?(:prototype)
      end

      private

      def find_presenter(path = nil)
        unless path.nil? || Pakyow.env?(:prototype)
          Templates.collapse_path(path) do |collapsed_path|
            if presenter = presenter_for_path(collapsed_path)
              return presenter
            end
          end
        end

        Presenter
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
