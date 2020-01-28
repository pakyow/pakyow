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
      name = name.to_sym
      if @__values.key?(name)
        @__values[name.to_sym]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @__values.key?(name.to_sym) || super
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
