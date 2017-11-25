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

        def required(*keys)
          required_keys.concat(keys).uniq!

          if block_given?
            verifier = Class.new(Verifier)
            verifier.instance_exec(&Proc.new)

            keys.each do |key|
              verifiers_by_key[key] = verifier
            end
          end
        end

        def optional(*keys)
          optional_keys.concat(keys).uniq!
        end

        def attribute(key, type)
          attributes[key] = type
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

        def attributes
          @attributes ||= {}
        end

        def verifiers_by_key
          @verifiers_by_key ||= {}
        end

        def sanitize(input)
          input = enforce_types(input)

          # this version excludes keys missing from input
          # input.select { |key, _| allowable_keys.include?(key) }

          # this version includes keys for missing input
          allowable_keys.each_with_object({}) { |key, values|
            values[key] = input[key]
          }
        end

        def enforce_types(input)
          input.select { |key, value|
            if type = attributes[key]
              type.valid?(value)
            else
              true
            end
          }
        end
      end

      attr_reader :values

      def initialize(input)
        @values = self.class.sanitize(input)
        @validator = self.class.validator.new(input)
      end

      def verify?
        self.class.required_keys.each do |required_key|
          return false if @values[required_key].nil?

          if verifier_for_key = self.class.verifiers_by_key[required_key]
            return false unless verifier_for_key.new(@values[required_key]).verify?
          end
        end

        @validator.valid?
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
    end
  end
end
