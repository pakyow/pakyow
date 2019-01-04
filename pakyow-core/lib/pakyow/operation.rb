# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/makeable"
require "pakyow/support/pipelined"
require "pakyow/support/pipelined/object"

require "pakyow/verification"

module Pakyow
  class Operation
    extend Support::ClassState
    class_state :__handlers, default: {}, inheritable: true

    extend Support::Makeable

    include Support::Pipelined
    include Support::Pipelined::Object

    attr_reader :values

    include Verification
    verifies :values

    def initialize(values = {})
      @values = values
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

    class << self
      # Perform input verification before performing the operation
      #
      # @see Pakyow::Verifier
      #
      # @api public
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
