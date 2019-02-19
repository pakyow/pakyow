# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/hookable"
require "pakyow/support/makeable"
require "pakyow/support/makeable/object_maker"

module Pakyow
  module Presenter
    # Reusable functionality for a component of your presentation.
    #
    class Component
      extend Support::Makeable

      extend Support::ClassState
      class_state :__presenter_class, default: Presenter, inheritable: true

      include Support::Hookable
      events :render

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
          @__presenter_class = Class.new(@__presenter_class) do
            class_eval(&block)
          end

          Support::ObjectMaker.define_object_on_target_with_constant_name(
            @__presenter_class, self, :Presenter
          )
        end
      end
    end
  end
end
