# frozen_string_literal: true

require "pakyow/validator"

module Pakyow
  module Validations
    # Validates that the value is unique within its data source.
    #
    module Unique
      def self.name
        :unique
      end

      def self.message(**)
        "must be unique"
      end

      def self.valid?(value, source:, **options)
        options[:context].app.data.public_send(source).public_send(:"by_#{options[:key]}", value).count == 0
      end
    end

    Validator.register_validation(Unique)
  end
end
