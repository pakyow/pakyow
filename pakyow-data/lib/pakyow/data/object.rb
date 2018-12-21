# frozen_string_literal: true

require "pakyow/support/bindable"
require "pakyow/support/makeable"
require "pakyow/support/indifferentize"

module Pakyow
  module Data
    # Wraps values for a data object returned by a source.
    #
    class Object
      include Support::Bindable

      attr_reader :values

      # @api private
      attr_accessor :originating_source

      extend Support::Makeable

      def initialize(values)
        @values = Support::IndifferentHash.new(values).freeze
      end

      def include?(key)
        super || @values.include?(key)
      end

      def [](key)
        key = key.to_s.to_sym
        if respond_to?(key)
          super
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

      class << self
        attr_reader :name

        def make(name, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, **kwargs, &block)
        end
      end
    end
  end
end
