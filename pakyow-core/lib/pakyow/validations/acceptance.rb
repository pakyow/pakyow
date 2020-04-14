# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"

require_relative "../validator"

module Pakyow
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
      using Support::Refinements::Array::Ensurable

      def self.message(**)
        "must be accepted"
      end

      def self.valid?(value, accepts: true, **)
        Array.ensure(accepts).include?(value)
      end
    end

    Validator.register_validation(Acceptance, :acceptance)
  end
end
