# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deprecatable"
require "pakyow/support/makeable"
require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

require "pakyow/behavior/verification"

module Pakyow
  class Operation
    extend Support::ClassState
    class_state :__handlers, default: {}, inheritable: true

    include Support::Makeable

    include Support::Pipeline
    include Support::Pipeline::Object

    include Behavior::Verification
    verifies :__values

    extend Support::Deprecatable

    attr_reader :__values

    def initialize(**values)
      @__values = values

      values.each_pair do |key, value|
        instance_variable_set(:"@#{key}", value)
      end
    end

    def perform
      call(self)
    rescue => error
      if handler = self.class.__handlers[error.class] || self.class.__handlers[:global]
        instance_exec(&handler); self
      else
        raise error
      end
    end

    def method_missing(name, *args, &block)
      value_key = if name[-1] == "="
        setter = true
        name[0..-2].to_sym
      else
        name.to_sym
      end

      if @__values.key?(value_key)
        if setter
          instance_variable_set(:"@#{value_key}", *args)
        else
          instance_variable_get(:"@#{value_key}")
        end
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      value_key = if name[-1] == "="
        name[0..-2].to_sym
      else
        name.to_sym
      end

      @__values.key?(value_key) || super
    end

    def values
      @__values
    end
    deprecate :values, solution: "prefer value methods"

    class << self
      # Perform input verification before performing the operation
      #
      # @see Pakyow::Verifier
      #
      def verify(&block)
        define_method :__verify do
          verify(&block)
        end

        action :__verify
      end

      def handle(error = nil, &block)
        @__handlers[error || :global] = block
      end
    end
  end
end
