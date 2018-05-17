# frozen_string_literal: true

require "forwardable"
require "set"

require "pakyow/presenter/attributes/attribute"

module Pakyow
  module Presenter
    module Attributes
      # Wraps the value for a set-type view attribute (e.g. class).
      #
      # Behaves just like a normal +Set+.
      #
      class Set < Attribute
        VALUE_SEPARATOR = " ".freeze

        extend Forwardable
        def_delegators :@value, :to_a, :any?, :empty?, :include?, :<<, :add, :delete, :clear

        def to_s
          @value.map(&:to_s).join(VALUE_SEPARATOR)
        end

        class << self
          def parse(value)
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
          def symbolize(arr)
            arr.map(&:to_sym)
          end
        end
      end
    end
  end
end
