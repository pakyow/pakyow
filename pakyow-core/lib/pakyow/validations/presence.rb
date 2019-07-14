# frozen_string_literal: true

require "pakyow/validator"

module Pakyow
  module Validations
    # Validates that the value is present, or that a value is non-empty, non-nil, and not a string
    # consisting of whitespace only characters. Example values that will not pass this validation:
    #
    # * +nil+
    # * +""+
    # * +"   "+
    # * +[]+
    # * +{}+
    #
    # @api public
    module Presence
      def self.message(**)
        "cannot be blank"
      end

      def self.valid?(value, **)
        if value.is_a?(String)
          !value.strip.empty?
        elsif value.respond_to?(:empty?)
          !value.empty?
        else
          !!value
        end
      end
    end

    Validator.register_validation(Presence, :presence)
  end
end
