# frozen_string_literal: true

require_relative "inflector"

require_relative "object_namespace"

module Pakyow
  module Support
    # A namespaced object name.
    #
    # @example
    #   name = Pakyow::Support::ObjectName.build(:foo, :bar, :application)
    #
    #   name.path
    #   => "foo/bar/application"
    #
    #   name.constant
    #   => "Foo::Bar:Application"
    #
    #   name.parts
    #   => [:foo, :bar, :application]
    #
    #   name.name
    #   => :application
    #
    class ObjectName
      class << self
        # Creates a namespaced object name.
        #
        def build(*namespaces, name)
          new(ObjectNamespace.new(*namespaces), name)
        end
      end

      attr_reader :namespace, :name, :parts, :path, :constant

      def initialize(namespace, name)
        @namespace, @name = namespace, name.to_sym

        rebuild
      end

      # Returns an object name for `name` within self.
      #
      # @example
      #   name = Pakyow::Support::ObjectName.build(:foo, :bar)
      #   name.constant
      #   => "Foo::Bar"

      #   name.isolate(:application).constant
      #   => "Foo::Bar::Application"
      #
      def isolate(name)
        ObjectName.new(ObjectNamespace.new(*@parts), name)
      end

      # Rebase into `namespace`.
      #
      def rebase(namespace)
        unless namespace.is_a?(ObjectNamespace)
          raise ArgumentError, "expected `#{namespace}' to be an instance of `Pakyow::ObjectNamespace'"
        end

        @namespace = namespace

        rebuild
      end

      alias to_s path

      def ==(other)
        other.is_a?(self.class) && @path == other.path
      end

      private def rebuild
        @parts = (@namespace.parts + [@name]).freeze
        @path = [@namespace.path, @name].reject(&:empty?).join("/").freeze
        @constant = if @namespace.parts.any?
          (@namespace.constant + "::" + Support.inflector.camelize(@name)).freeze
        else
          Support.inflector.camelize(@name).freeze
        end
      end
    end
  end
end
