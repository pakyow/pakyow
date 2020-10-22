# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/deep_dup"

require_relative "errors"
require_relative "types"
require_relative "validator"
require_relative "validations"

module Pakyow
  class Verifier
    class Result
      using Support::DeepDup

      attr_writer :validation

      def initialize
        @errors = {}
        @nested = {}
        @validation = nil
        @defaults = []
      end

      def initialize_copy(_)
        @errors = @errors.deep_dup
        @nested = @nested.deep_dup
        @defaults = @defaults.dup
        @validation = nil
      end

      def error(key, message)
        (@errors[key] ||= []) << message
      end

      def nested(key, result)
        @nested[key] = result
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

      def default(key)
        @defaults << key.to_sym
      end

      def default?(key)
        @defaults.include?(key.to_sym)
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

    using Support::DeepDup
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

    def initialize_copy(_)
      @types = @types.deep_dup
      @defaults = @defaults.deep_dup
      @messages = @messages.deep_dup
      @required_keys = @required_keys.dup
      @optional_keys = @optional_keys.dup
      @allowable_keys = @allowable_keys.dup
      @verifiers_by_key = @verifiers_by_key.deep_dup
      @validator = @validator.dup
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

    def call(value, context: nil)
      result = Result.new

      if !value.nil? && @allowable_keys.any?
        Array.ensure(value).each do |each_value|
          @allowable_keys.each do |allowable_key|
            # Typecase the value for each key.
            #
            if each_value.key?(allowable_key)
              value_for_key = each_value[allowable_key]

              if (type = @types[allowable_key])
                value_for_key = type[value_for_key]
              end

              each_value[allowable_key] = value_for_key
            end

            if each_value[allowable_key].nil?
              if default?(allowable_key)
                result.default(allowable_key)
                each_value[allowable_key] = default(allowable_key)
              end

              if @required_keys.include?(allowable_key)
                result.error(allowable_key, @messages[allowable_key])
              else
                next
              end
            end

            if (verifier_for_key = @verifiers_by_key[allowable_key])
              result.nested(allowable_key, verifier_for_key.call(each_value[allowable_key], context: context))
            end
          end

          sanitize!(each_value) if result.verified?
        end
      end

      if !value.nil? && @validator.any?
        result.validation = @validator.call(value, context: context)
      end

      result
    end

    def call!(value, context: nil)
      result = call(value, context: context)

      unless result.verified?
        error = InvalidData.new_with_message(:verification)
        error.context = {object: value, result: result}
        raise error
      end

      result
    end

    def default?(key)
      @defaults.include?(key.to_sym)
    end

    def default(key)
      key = key.to_sym
      if @defaults.include?(key)
        resolve_default_value(@defaults[key])
      end
    end

    private def resolve_default_value(value)
      case value
      when Proc
        value.call
      else
        value
      end
    end

    private def sanitize!(value)
      value.select! do |key, _|
        @allowable_keys.include?(key.to_sym)
      end

      value
    end
  end
end
