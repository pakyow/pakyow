# frozen_string_literal: true

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
    end
  end
end
