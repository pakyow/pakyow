# frozen_string_literal: true

module Pakyow
  module Data
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
        WHITESPACE_ONLY = /^\s*$/

        def self.name
          :presence
        end

        def self.valid?(value, **)
          if value.is_a?(String)
            !value.match?(WHITESPACE_ONLY)
          elsif value.respond_to?(:empty?)
            !value.empty?
          else
            !!value
          end
        end
      end

      Validator.register_validation(Presence)
    end
  end
end
