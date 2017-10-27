require "pakyow/presenter/attributes/attribute"

require "set"

module Pakyow
  module Presenter
    module Attributes
      # Wraps the value for a set-type view attribute (e.g. class).
      #
      # Behaves just like a normal +Set+.
      #
      class Set < Attribute
        VALUE_SEPARATOR = " ".freeze

        def self.parse(value)
          if value.is_a?(::Set)
            new(symbolize(value))
          elsif value.is_a?(Array)
            new(::Set.new(symbolize(value)))
          elsif value.respond_to?(:to_s)
            new(::Set.new(symbolize(value.to_s.split(VALUE_SEPARATOR))))
          else
            raise ArgumentError.new("Expected value to be an Array, Set, or String")
          end
        end

        # @api private
        def self.symbolize(arr)
          arr.map(&:to_sym)
        end

        def to_s
          map(&:to_s).join(VALUE_SEPARATOR)
        end
      end
    end
  end
end
