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

      attr_reader :errors

      def initialize(value)
        @value = value
        @errors = []
      end

      def valid?
        self.class.validations.each do |validation, options|
          unless Validator.validation_object_for(validation).valid?(@value, *options)
            @errors << validation
          end
        end

        @errors.empty?
      end
    end
  end
end
