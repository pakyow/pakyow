# frozen_string_literal: true

require "pakyow/data/errors"

module Pakyow
  module Data
    class Validator
      class << self
        def validate(validation, **options)
          validations << [validation, options]
        end

        def register_validation(validation, validation_object)
          validation_objects[validation] = validation_object
        end

        def validation_object_for(validation)
          validation_objects[validation] ||
            raise(UnknownValidationError.new("Unknown validation named `#{validation}'"))
        end

        def validations
          @validations ||= []
        end

        def validation_objects
          @validation_objects ||= {}
        end
      end

      def initialize(value)
        @value = value
      end

      def valid?
        self.class.validations.each do |validation, options|
          return false unless Validator.validation_object_for(validation).valid?(@value, *options)
        end

        true
      end
    end
  end
end
