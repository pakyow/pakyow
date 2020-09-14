# frozen_string_literal: true

require_relative "inflector"

module Pakyow
  module Support
    # An object namespace, typically used indirectly via {ObjectName}.
    #
    class ObjectNamespace
      class << self
        # Creates a namespaced object name.
        #
        def build(*namespaces)
          new(*namespaces)
        end
      end

      attr_reader :namespaces, :constant, :path

      def initialize(*namespaces)
        @namespaces = namespaces.map(&:to_sym).freeze
        @constant = @namespaces.map { |namespace|
          Support.inflector.camelize(namespace)
        }.join("::").freeze
        @path = @namespaces.join("/").freeze
      end

      alias parts namespaces
      alias to_s path

      def ==(other)
        other.is_a?(self.class) && @path == other.path
      end
    end
  end
end
