# frozen_string_literal: true

require "pakyow/data/errors"

module Pakyow
  module Data
    class Validator
      class << self
        def validate(validation_name = nil, **options)
          validation_object = if block_given?
            Validations::Inline.new(validation_name, Proc.new)
          else
            validation_object_for(validation_name)
          end

          validations << [validation_object, options]
        end

        def register_validation(validation_object)
          Validator.validation_objects[validation_object.name] = validation_object
        end

        def validation_object_for(validation)
          Validator.validation_objects[validation] ||
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

      def initialize(value, context: nil)
        @value, @context = value, context
        @errors = []
      end

      def valid?
        self.class.validations.each do |validation, options|
          unless validation.valid?(@value, context: @context, **options)
            @errors << validation.name
          end
        end

        @errors.empty?
      end
    end
  end
end
