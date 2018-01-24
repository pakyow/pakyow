# frozen_string_literal: true

module Pakyow
  module Data
    module Validations
      # Validates acceptance by ensuring that the given value is present (@see Presence), or
      # (optionally) that the given value matches the +accepts+ option.
      #
      # @example
      #   validate :acceptance
      #
      # @example
      #   validate :acceptance, accepts: "yes"
      #
      # @api public
      module Acceptance
        def self.name
          :acceptance
        end

        def self.valid?(value, **options)
          if options.key?(:accepts)
            value == options[:accepts]
          else
            Presence.valid?(value)
          end
        end
      end

      Validator.register_validation(Acceptance)
    end
  end
end
