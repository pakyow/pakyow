# frozen_string_literal: true

require "forwardable"
require "set"

require "pakyow/support/safe_string"

require_relative "attribute"

module Pakyow
  module Presenter
    class Attributes
      # Wraps the value for a set-type view attribute (e.g. class).
      #
      # Behaves just like a normal +Set+.
      #
      class Set < Attribute
        VALUE_SEPARATOR = " ".freeze

        extend Forwardable
        def_delegators :@value, :to_a, :any?, :empty?, :clear

        include Support::SafeStringHelpers

        def include?(value)
          @value.include?(value.to_s)
        end

        def <<(value)
          @value << ensure_html_safety(value)
        end

        def add(value)
          @value.add(ensure_html_safety(value))
        end

        def delete(value)
          @value.delete(value.to_s)
        end

        def to_s
          @value.to_a.join(VALUE_SEPARATOR)
        end

        class << self
          include Support::SafeStringHelpers

          def parse(value)
            if value.is_a?(Array) || value.is_a?(::Set)
              new(::Set.new(value.map { |v| ensure_html_safety(v) }))
            elsif value.respond_to?(:to_s)
              new(::Set.new(value.to_s.split(VALUE_SEPARATOR).map { |v| ensure_html_safety(v) }))
            else
              raise ArgumentError.new("expected value to be an Array, Set, or String")
            end
          end
        end
      end
    end
  end
end
