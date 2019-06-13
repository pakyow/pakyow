# frozen_string_literal: true

module Pakyow
  class Plugin
    # @api private
    class HelperCaller
      def initialize(connection:, helpers:, plugin:)
        @connection, @helpers, @plugin = connection, helpers, plugin
      end

      def method_missing(method_name, *args, &block)
        @connection.instance_variable_set(:@app, @plugin)
        @helpers.public_send(method_name, *args, &block).tap do
          @connection.instance_variable_set(:@app, @plugin.parent)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @helpers.respond_to?(method_name) || super
      end
    end
  end
end
