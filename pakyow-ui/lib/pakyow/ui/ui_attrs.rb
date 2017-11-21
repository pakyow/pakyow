# frozen_string_literal: true

require_relative "ui_instructable"

module Pakyow
  module UI
    # Builds up instructions for changing view attributes.
    #
    # @api private
    class UIAttrs
      include Instructable

      def nested_instruct_object(_method, _data, _scope)
        UIAttrs.new
      end

      def method_missing(method, value)
        nested_instruct(method, value)
      end

      def class
        method_missing(:class, nil)
      end

      def id
        method_missing(:id, nil)
      end

      def <<(value)
        method_missing(:insert, value)
      end

      def []=(method, value)
        method_missing(method, value)
      end

      def [](method)
        method_missing(method, nil)
      end
    end
  end
end
