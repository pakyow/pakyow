# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/types"
require "pakyow/validator"

module Pakyow
  class Verifier
    class << self
      extend Forwardable
      def_delegators :validator, :validate

      def validator
        @validator ||= Class.new(Validator)
      end

      def required(key, type = nil)
        key = key.to_sym
        required_keys.push(key).uniq!

        if type
          types[key] = Types.type_for(type)
        end

        if block_given?
          verifier = Class.new(Verifier)
          verifier.instance_exec(&Proc.new)
          verifiers_by_key[key] = verifier
        end
      end

      def optional(key, type = nil)
        key = key.to_sym
        optional_keys.push(key).uniq!

        if type
          types[key] = Types.type_for(type)
        end

        if block_given?
          verifier = Class.new(Verifier)
          verifier.instance_exec(&Proc.new)
          verifiers_by_key[key] = verifier
        end
      end

      def types
        @types ||= {}
      end

      def allowable_keys
        required_keys + optional_keys
      end

      def required_keys
        @required_keys ||= []
      end

      def optional_keys
        @optional_keys ||= []
      end

      def verifiers_by_key
        @verifiers_by_key ||= {}
      end

      def sanitize(input)
        input.select! do |key, _|
          allowable_keys.include?(key)
        end

        allowable_keys.each do |key|
          next unless input.key?(key)

          value = input[key]

          if type = types[key]
            value = type[value]
          end

          input[key] = value
        end

        input
      end
    end

    using Support::Refinements::Array::Ensurable

    attr_reader :validator, :values, :errors

    def initialize(input, context: nil)
      input ||= {}

      @context = context

      if should_sanitize?(input)
        @values = self.class.sanitize(input)
      end

      if should_validate?(input)
        @validator = self.class.validator.new(input, context: @context)
      end

      @errors = {}
    end

    def verify?
      self.class.allowable_keys.each do |allowable_key|
        if @values[allowable_key].nil?
          if self.class.required_keys.include?(allowable_key)
            (@errors[allowable_key] ||= []) << :required
          else
            next
          end
        end

        if verifier_for_key = self.class.verifiers_by_key[allowable_key]
          Array.ensure(@values[allowable_key]).each do |value_to_verify|
            verifier_instance_for_key = verifier_for_key.new(value_to_verify, context: @context)
            unless verifier_instance_for_key.verify?
              if verifier_instance_for_key.validating?
                (@errors[allowable_key] ||= []).concat(verifier_instance_for_key.validator.errors)
              else
                @errors[allowable_key] = verifier_instance_for_key.errors
              end
            end
          end
        end
      end

      @errors.empty? && (!validating? || (validating? && @validator.valid?))
    end

    def invalid_keys
      self.class.required_keys.each_with_object([]) { |required_key, invalid_keys|
        value = @values[required_key]
        if value.nil? || value.empty?
          invalid_keys << required_key
        end
      }
    end

    def >>(other)
      other.new(@values)
    end

    def validating?
      !@validator.nil? && !@validator.class.validations.empty?
    end

    def messages(errors = @errors)
      errors.each_with_object({}) { |(key, error_keys), error_messages|
        error_messages[key] = if error_keys.is_a?(Hash)
          messages(error_keys)
        else
          error_keys.map { |error_key|
            message_for(error_key)
          }
        end
      }
    end

    DEFAULT_ERROR_MESSAGES = {
      default: "is invalid",
      required: "is required",
      presence: "is not present"
    }.freeze

    def message_for(error_key)
      DEFAULT_ERROR_MESSAGES[error_key] || DEFAULT_ERROR_MESSAGES[:default]
    end

    protected

    def should_sanitize?(input)
      input.is_a?(Pakyow::Support::IndifferentHash) || input.is_a?(Hash)
    end

    def should_validate?(input)
      !input.nil?
    end
  end
end
