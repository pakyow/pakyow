# frozen_string_literal: true

require "pakyow/validator"

module Pakyow
  module Validations
    # Validates that the value is a valid email address.
    #
    # @api public
    module Email
      REGEX = /\A[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}\z/i

      def self.message(**)
        "must be a valid email address"
      end

      def self.valid?(value, **)
        value.to_s.match?(REGEX)
      end
    end

    Validator.register_validation(Email, :email)
  end
end
