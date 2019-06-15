# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/types"
require "pakyow/validator"

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

      def messages
        if validating?
          messages = @validation.messages
        else
          messages = {}

          @errors.each_pair do |key, value|
            messages[key] = value
          end

          @nested.each_pair do |key, verifier|
            nested_messages = verifier.messages

            unless nested_messages.empty?
              messages[key] = nested_messages
            end
          end
        end

        messages
      end
    end

    using Support::Refinements::Array::Ensurable

    extend Forwardable
    def_delegators :@validator, :validate

    def initialize(key = nil, &block)
      @key = key
      @types = {}
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

    def optional(key, type = nil, &block)
      key = key.to_sym
      @optional_keys.push(key).uniq!
      @allowable_keys.push(key).uniq!

      if type
        @types[key] = Types.type_for(type)
      end

      if block
        @verifiers_by_key[key] = self.class.new(key, &block)
      end
    end

    def call(values, context: nil)
      values ||= {}

      if should_sanitize?(values)
        values = sanitize(values)
      end

      result = Result.new

      if should_validate?(values)
        result.validation(@validator.call(values, context: context))
      end

      @allowable_keys.each do |allowable_key|
        if values[allowable_key].nil?
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

      result
    end

    private

    def sanitize(values)
      values.select! do |key, _|
        @allowable_keys.include?(key.to_sym)
      end

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

    def should_sanitize?(values)
      values.is_a?(Pakyow::Support::IndifferentHash) || values.is_a?(Hash) || values.is_a?(Connection::Params)
    end

    def should_validate?(values)
      @validator.any? && !values.nil?
    end
  end
end
