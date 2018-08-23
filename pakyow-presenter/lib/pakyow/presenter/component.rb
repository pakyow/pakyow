# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/hookable"
require "pakyow/support/makeable"

module Pakyow
  module Presenter
    # Reusable functionality for a component of your presentation.
    #
    class Component
      extend Support::Makeable

      extend Support::ClassState
      class_state :__presenter_extension, inheritable: true

      include Support::Hookable
      known_events :render

      # @api private
      attr_reader :connection

      def initialize(connection:)
        @connection = connection
      end

      def perform
        # intentionally empty
      end

      private

      class << self
        def presenter(&block)
          @__presenter_extension = block
        end
      end
    end
  end
end
