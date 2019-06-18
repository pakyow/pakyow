# frozen_string_literal: true

require "pakyow/support/inflector"
require "pakyow/support/makeable/object_namespace"

module Pakyow
  module Support
    # @api private
    class ObjectName
      class << self
        def namespace(*namespaces, object_name)
          ObjectName.new(
            ObjectNamespace.new(*namespaces),
            object_name
          )
        end
      end

      attr_reader :namespace, :name

      def initialize(namespace, name)
        @namespace, @name = namespace, name.to_sym
      end

      def isolated(subobject_name)
        ObjectName.new(
          ObjectNamespace.new(*parts),
          subobject_name
        )
      end

      def parts
        namespace.parts + [@name]
      end

      def to_s
        [@namespace, @name].join("/")
      end

      def constant
        [@namespace.constant, Support.inflector.camelize(@name)].join("::")
      end
    end
  end
end
