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
        query = options[:context].app.data.public_send(source).public_send(:"by_#{options[:key]}", value)

        if updating = options[:updating]
          if updating.is_a?(Data::Result)
            query.count == 0 || query.any? { |result|
              result[updating.__proxy.source.class.primary_key_field] == updating[updating.__proxy.source.class.primary_key_field]
            }
          else
            raise ArgumentError, "Expected `#{updating.class}' to be a `Pakyow::Data::Result'"
          end
        else
          query.count == 0
        end
      end
    end

    Validator.register_validation(Unique)
  end
end
