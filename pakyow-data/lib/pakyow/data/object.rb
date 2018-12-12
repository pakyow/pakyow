# frozen_string_literal: true

require "pakyow/support/makeable"
require "pakyow/support/indifferentize"

module Pakyow
  module Data
    # Wraps values for a data object returned by a source.
    #
    class Object
      attr_reader :values

      # @api private
      attr_accessor :originating_source

      extend Support::Makeable

      def initialize(values)
        @values = Support::IndifferentHash.new(values).freeze
      end

      def include?(key)
        value_methods.include?(key) || @values.include?(key)
      end

      def value?(key)
        value_methods.include?(key) || @values.value?(key)
      end

      def [](key)
        key = key.to_s.to_sym
        if value_methods.include?(key)
          public_send(key)
        else
          @values[key]
        end
      end

      def method_missing(name, *_args)
        if include?(name)
          @values[name]
        else
          super
        end
      end

      def respond_to_missing(name, *)
        include?(name) || super
      end

      def to_h
        @values
      end

      def to_json(*)
        @values.to_json
      end

      def ==(other)
        other.class == self.class && other.values == @values
      end

      private

      def value_methods
        (public_methods - self.class.superclass.public_instance_methods)
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
