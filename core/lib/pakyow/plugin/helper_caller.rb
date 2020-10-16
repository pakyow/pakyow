# frozen_string_literal: true

module Pakyow
  class Plugin
    # @api private
    class HelperCaller
      def initialize(connection:, helpers:, plugin:)
        @connection, @helpers, @plugin = connection, helpers, plugin
      end

      def method_missing(method_name, *args, &block)
        @helpers.public_send(method_name, *args, &block)
      end

      def respond_to_missing?(method_name, include_private = false)
        @helpers.respond_to?(method_name) || super
      end
    end
  end
end
