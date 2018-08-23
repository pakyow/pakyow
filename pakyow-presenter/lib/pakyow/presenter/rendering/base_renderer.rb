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
      known_events :render

      include Support::Pipelined
      include Support::Pipelined::Haltable

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
    end
  end
end
