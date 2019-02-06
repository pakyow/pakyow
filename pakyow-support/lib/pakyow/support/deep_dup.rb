# frozen_string_literal: true

require "delegate"

module Pakyow
  module Support
    # Refines Object, Array, and Hash with support for deep_dup.
    #
    # @example
    #   using DeepDup
    #   state = { "foo" => ["bar"] }
    #   duped = state.deep_dup
    #
    #   state.keys[0] === duped.keys[0]
    #   => false
    #
    #   state.values[0][0] === duped.values[0][0]
    #   => false
    #
    module DeepDup
      # Objects that can't be copied.
      UNDUPABLE = [Symbol, Integer, NilClass, TrueClass, FalseClass, Class, Module].freeze

      [Object, Delegator].each do |klass|
        refine klass do
          # Returns a copy of the object.
          #
          def deep_dup
            if UNDUPABLE.include?(self.class)
              self
            else
              dup
            end
          end
        end
      end

      refine Array do
        # Returns a deep copy of the array.
        #
        def deep_dup
          map(&:deep_dup)
        end
      end

      refine Hash do
        # Returns a deep copy of the hash.
        #
        def deep_dup
          each_with_object(dup) do |(key, value), hash|
            hash.delete(key)
            hash[key.deep_dup] = value.deep_dup
          end
        end
      end
    end
  end
end
