# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"

require_relative "attribute"

module Pakyow
  module Presenter
    class Attributes
      # Wraps the value for a hash-type view attribute (e.g. style).
      #
      # Behaves just like a normal +Hash+.
      #
      class Hash < Attribute
        VALUE_SEPARATOR = ":"
        PAIR_SEPARATOR = ";"

        WRITE_VALUE_SEPARATOR = ": "
        WRITE_PAIR_SEPARATOR = "; "

        extend Forwardable
        def_delegators :@value, :any?, :empty?, :clear

        include Support::SafeStringHelpers

        def include?(key)
          @value.include?(key.to_s)
        end

        def value?(value)
          @value.value?(value.to_s)
        end

        def [](key)
          @value[key.to_s]
        end

        def []=(key, value)
          @value[ensure_html_safety(key)] = ensure_html_safety(value)
        end

        def delete(key)
          @value.delete(key.to_s)
        end

        def to_s
          string = ::String.new
          first = true
          @value.each do |key, value|
            unless first
              string << WRITE_PAIR_SEPARATOR
            end

            string << key
            string << WRITE_VALUE_SEPARATOR
            string << value
            first = false
          end

          unless string.empty?
            string += PAIR_SEPARATOR
          end

          string
        end

        class << self
          include Support::SafeStringHelpers

          def parse(value)
            if value.is_a?(::Hash)
              new(::Hash[value.map { |k, v| [ensure_html_safety(k), ensure_html_safety(v.to_s)] }])
            elsif value.respond_to?(:to_s)
              new(value.to_s.split(PAIR_SEPARATOR).each_with_object({}) { |style, attributes|
                key, value = style.split(VALUE_SEPARATOR)
                next unless key && value
                attributes[ensure_html_safety(key.strip)] = ensure_html_safety(value.strip)
              })
            else
              raise ArgumentError.new("expected value to be a Hash or String")
            end
          end
        end
      end
    end
  end
end
