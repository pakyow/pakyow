# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/errors"

module Pakyow
  class Validator
    class Result
      def initialize
        @errors = []
      end

      def error(validation, options)
        @errors << [validation, options]
      end

      def valid?
        @errors.empty?
      end

      def messages
        @errors.map { |validation, options|
          options[:message] || validation.message(**options)
        }
      end
    end

    extend Support::ClassState
    class_state :validation_objects, default: {}

    class << self
      def register_validation(validation_object)
        @validation_objects[validation_object.name] = validation_object
      end

      # @api private
      def validation_object_for(validation)
        @validation_objects[validation] || raise(
          UnknownValidationError.new_with_message(validation: validation)
        )
      end
    end

    require "pakyow/validations"

    def initialize(key = nil, &block)
      @key = key
      @validations = []

      if block
        instance_eval(&block)
      end
    end

    def any?
      @validations.any?
    end

    def validate(validation_name = nil, **options)
      validation_object = if block_given?
        Validations::Inline.new(validation_name, Proc.new)
      else
        self.class.validation_object_for(validation_name)
      end

      @validations << [validation_object, options]
    end

    def call(values, context: nil)
      result = Result.new

      @validations.each do |validation, options|
        unless validation.valid?(values, key: @key, context: context, **options)
          result.error(validation, options)
        end
      end

      result
    end
  end
end
