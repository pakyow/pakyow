# frozen_string_literal: true

require_relative "../validator"

module Pakyow
  module Validations
    # Validates that the value is of an expected length.
    #
    # @api public
    module Length
      def self.message(minimum: nil, maximum: nil, **)
        if minimum && maximum
          "must have between #{minimum} and #{maximum} characters"
        elsif minimum
          "must have more than #{minimum} #{wording(minimum)}"
        elsif maximum
          "must have less than #{maximum} #{wording(maximum)}"
        end
      end

      def self.valid?(value, minimum: nil, maximum: nil, **)
        unless minimum.nil?
          return false if value.length < minimum
        end

        unless maximum.nil?
          return false if value.length > maximum
        end

        true
      end

      def self.wording(n)
        n == 1 ? "character" : "characters"
      end
    end

    Validator.register_validation(Length, :length)
  end
end
