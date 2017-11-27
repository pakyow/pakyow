# frozen_string_literal: true

require "pakyow/data/validator"

require "forwardable"

module Pakyow
  module Data
    class Verifier
      class << self
        extend Forwardable
        def_delegators :validator, :validate

        def validator
          @validator ||= Class.new(Validator)
        end

        def required(key, type = nil)
          required_keys.push(key).uniq!

          if type
            types[key] = Types.type_for(type, :input)
          end

          if block_given?
            verifier = Class.new(Verifier)
            verifier.instance_exec(&Proc.new)
            verifiers_by_key[key] = verifier
          end
        end

        def optional(key, type = nil)
          optional_keys.push(key).uniq!

          if type
            types[key] = Types.type_for(type, :input)
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
          # this version excludes keys missing from input
          # input.select { |key, _| allowable_keys.include?(key) }

          # this version includes keys for missing input
          allowable_keys.each do |key|
            value = input[key]
            if type = types[key]
              value = type[value]
            end

            input[key] = value
          end

          input
        end
      end

      attr_reader :validator, :values, :errors

      def initialize(input)
        input ||= {}

        if should_sanitize?(input)
          @values = self.class.sanitize(input)
        end

        if should_validate?(input)
          @validator = self.class.validator.new(input)
        end

        @errors = {}
      end

      def verify?
        self.class.required_keys.each do |required_key|
          if @values[required_key].nil?
            (@errors[required_key] ||= []) << :required
          end

          if verifier_for_key = self.class.verifiers_by_key[required_key]
            verifier_instance_for_key = verifier_for_key.new(@values[required_key])
            unless verifier_instance_for_key.verify?
              if verifier_instance_for_key.validating?
                (@errors[required_key] ||= []).concat(verifier_instance_for_key.validator.errors)
              else
                @errors[required_key] = verifier_instance_for_key.errors
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

      protected

      def should_sanitize?(input)
        input.is_a?(Pakyow::Support::IndifferentHash) || input.is_a?(Hash)
      end

      def should_validate?(input)
        !input.nil?
      end
    end
  end
end
