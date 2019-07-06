# frozen_string_literal: true

require "pakyow/support/bindable"
require "pakyow/support/class_state"
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

      extend Support::ClassState
      class_state :__serialized_methods, default: [], inheritable: true

      extend Support::Makeable

      def initialize(values)
        @values = Support::IndifferentHash.new(values).freeze
      end

      def source
        @originating_source.__object_name.name
      end

      def include?(key)
        respond_to?(key)
      end
      alias key? include?

      def [](key)
        key = key.to_s.to_sym
        if respond_to?(key)
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

      def respond_to_missing?(name, *)
        @values.include?(name) || super
      end

      def to_h
        hash = @values.dup
        self.class.__serialized_methods.each do |method|
          hash[method] = public_send(method)
        end

        hash
      end

      def to_json(*)
        @values.to_json
      end

      def ==(other)
        comparator = case other
        when self.class
          other
        when Result
          other.__getobj__
        else
          nil
        end

        comparator && comparator.class == self.class && comparator.values == @values
      end

      class << self
        attr_reader :name

        # @api private
        def make(name, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, **kwargs, &block)
        end

        def serialize(*methods)
          @__serialized_methods.concat(methods.map(&:to_sym)).uniq!
        end
      end
    end
  end
end
