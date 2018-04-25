# frozen_string_literal: true

require "forwardable"

require "pakyow/support/makeable"

module Pakyow
  module Data
    # Wraps values for a data object returned by a source.
    #
    class Object
      attr_reader :values

      extend Support::Makeable

      extend Forwardable
      def_delegators :@values, :include?, :value?, :[]

      def initialize(values)
        @values = values
      end

      def method_missing(name, *args)
        if @values.include?(name)
          @values[name]
        end
      end

      def respond_to_missing(name, *)
        @values.include?(name)
      end

      class << self
        attr_reader :name

        def make(name, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, **kwargs, &block)
        end
      end
    end
  end
end
