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
      UNDUPABLE = [Symbol, Fixnum, NilClass, TrueClass, FalseClass].freeze

      refine Object do
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

      refine Array do
        # Returns a deep copy of the array.
        #
        def deep_dup
          each_with_object([]) do |value, array|
            array << value.deep_dup
          end
        end
      end

      refine Hash do
        # Returns a deep copy of the hash.
        #
        def deep_dup
          each_with_object({}) do |(key, value), hash|
            hash[key.deep_dup] = value.deep_dup
          end
        end
      end
    end
  end
end
