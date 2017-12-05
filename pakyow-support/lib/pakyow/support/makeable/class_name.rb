# frozen_string_literal: true

require "pakyow/support/makeable/class_namespace"

module Pakyow
  module Support
    # @api private
    class ClassName
      class << self
        def namespace(*namespaces, class_name)
          ClassName.new(
            ClassNamespace.new(*namespaces),
            class_name
          )
        end
      end

      attr_reader :namespace, :name

      def initialize(namespace, name)
        @namespace, @name = namespace, name.to_sym
      end

      def subclass(subclass_name)
        ClassName.new(
          ClassNamespace.new(*parts),
          subclass_name
        )
      end

      def parts
        namespace.parts + [@name]
      end

      def to_s
        [@namespace, @name].join("/")
      end
    end
  end
end
