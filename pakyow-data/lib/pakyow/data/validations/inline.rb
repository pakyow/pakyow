# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Data
    module Validations
      # Wraps an inline validation proc so that we know its given name.
      #
      # @api private
      class Inline
        extend Forwardable

        attr_reader :name

        def initialize(name, block)
          @name, @block = name, block
        end

        def valid?(value, context: nil)
          if context
            context.instance_exec(value, &@block)
          else
            @block.call(value)
          end
        end
      end
    end
  end
end
