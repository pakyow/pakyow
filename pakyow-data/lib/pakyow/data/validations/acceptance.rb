# frozen_string_literal: true

module Pakyow
  module Data
    module Validations
      # Ensures that the given value matches an acceptance value. By default, the value must equal
      # +true+. Use the `accepts` keyword argument to pass one or more comparison values.
      #
      # @example
      #   validate :acceptance
      #
      # @example
      #   validate :acceptance, accepts: ["yes", "y"]
      #
      # @api public
      module Acceptance
        def self.name
          :acceptance
        end

        def self.valid?(value, accepts: true)
          Array.ensure(accepts).include?(value)
        end
      end

      Validator.register_validation(Acceptance)
    end
  end
end
