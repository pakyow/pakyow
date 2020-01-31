# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/errors"
require "pakyow/types"
require "pakyow/validator"
require "pakyow/validations"

module Pakyow
  class Verifier
    class Result
      def initialize
        @errors = {}
        @nested = {}
        @validation = nil
      end

      def error(key, message)
        (@errors[key] ||= []) << message
      end

      def nested(key, result)
        @nested[key] = result
      end

      def validation(result)
        @validation = result
      end

      def verified?
        @errors.empty? && (!validating? || @validation.valid?) && @nested.all? { |_, result|
          result.verified?
        }
      end

      def validating?
        !@validation.nil?
      end

      def messages(type: :default)
        if validating?
          messages = @validation.messages(type: type)
        else
          messages = {}

          @errors.each_pair do |key, value|
            messages[key] = value.map { |each_value|
              Verifier.formatted_message(each_value, type: type, key: key)
            }
          end

          @nested.each_pair do |key, verifier|
            nested_messages = verifier.messages(type: type)

            unless nested_messages.empty?
              messages[key] = nested_messages
            end
          end
        end

        messages
      end
    end

    class << self
      def formatted_message(message, type:, key:)
        case type
        when :full
          "#{key} #{message}"
        when :presentable
          "#{Support.inflector.humanize(key)} #{message}"
        else
          message
        end
      end
    end

    using Support::Refinements::Array::Ensurable

    extend Forwardable
    def_delegators :@validator, :validate

    # @api private
    attr_reader :allowable_keys

    def initialize(key = nil, &block)
      @key = key
      @types = {}
      @defaults = {}
      @messages = {}
      @required_keys = []
      @optional_keys = []
      @allowable_keys = []
      @verifiers_by_key = {}
      @validator = Validator.new(key)

      if block
        instance_eval(&block)
      end
    end

    def required(key, type = nil, message: "is required", &block)
      key = key.to_sym
      @required_keys.push(key).uniq!
      @allowable_keys.push(key).uniq!
      @messages[key] = message

      if type
        @types[key] = Types.type_for(type)
      end

      if block
        @verifiers_by_key[key] = self.class.new(key, &block)
      end
    end

    def optional(key, type = nil, default: default_omitted = true, &block)
      key = key.to_sym
      @optional_keys.push(key).uniq!
      @allowable_keys.push(key).uniq!

      unless default_omitted
        @defaults[key] = default
      end

      if type
        @types[key] = Types.type_for(type)
      end

      if block
        @verifiers_by_key[key] = self.class.new(key, &block)
      end
    end

    def call(values, context: nil)
      values ||= {}

      values_are_mutable = mutable?(values)

      if values_are_mutable
        typecast!(values)
      end

      result = Result.new

      if validatable?(values)
        result.validation(@validator.call(values, context: context))
      end

      @allowable_keys.each do |allowable_key|
        if values[allowable_key].nil?
          if @defaults.include?(allowable_key)
            values[allowable_key] = @defaults[allowable_key]
          end

          if @required_keys.include?(allowable_key)
            result.error(allowable_key, @messages[allowable_key])
          else
            next
          end
        end

        if verifier_for_key = @verifiers_by_key[allowable_key]
          Array.ensure(values[allowable_key]).each do |values_for_key|
            result.nested(allowable_key, verifier_for_key.call(values_for_key, context: context))
          end
        end
      end

      if values_are_mutable && result.verified?
        sanitize!(values)
      end

      result
    end

    def call!(values, context: nil)
      result = call(values, context: context)

      unless result.verified?
        error = InvalidData.new_with_message(:verification)
        error.context = { object: values, result: result }
        raise error
      end

      result
    end

    private def sanitize!(values)
      values.select! do |key, _|
        @allowable_keys.include?(key.to_sym)
      end

      values
    end

    private def typecast!(values)
      @allowable_keys.each do |key|
        key = key.to_sym

        if values.key?(key)
          value = values[key]

          if type = @types[key]
            value = type[value]
          end

          values[key] = value
        end
      end

      values
    end

    # @api private
    MUTATABLE_TYPES = %w(
      Hash
      Pakyow::Support::IndifferentHash
      Pakyow::Connection::Params
    ).freeze

    private def mutable?(values)
      MUTATABLE_TYPES.include?(values.class.name)
    end

    private def validatable?(values)
      @validator.any? && !values.nil?
    end
  end
end
