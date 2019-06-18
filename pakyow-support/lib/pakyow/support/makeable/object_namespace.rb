# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Support
    # @api private
    class ObjectNamespace
      def initialize(*namespaces)
        @namespaces = namespaces.map(&:to_sym)
      end

      def parts
        @namespaces
      end

      def to_s
        @namespaces.join("/")
      end

      def constant
        @namespaces.map { |namespace|
          Support.inflector.camelize(namespace)
        }.join("::")
      end
    end
  end
end
