# frozen_string_literal: true

require "pakyow/presenter/attributes/attribute"

module Pakyow
  module Presenter
    module Attributes
      # Wraps the value for a hash-type view attribute (e.g. style).
      #
      # Behaves just like a normal +Hash+.
      #
      class Hash < Attribute
        VALUE_SEPARATOR = ":".freeze
        PAIR_SEPARATOR  = ";".freeze

        def self.parse(value)
          if value.is_a?(::Hash)
            new(value)
          elsif value.respond_to?(:to_s)
            new(value.to_s.split(PAIR_SEPARATOR).each_with_object({}) { |style, attributes|
              key, value = style.split(VALUE_SEPARATOR)
              next unless key && value
              attributes[key.strip.to_sym] = value.strip
            })
          else
            raise ArgumentError.new("Expected value to be a Hash or String")
          end
        end

        def to_s
          to_a.map { |value| value.join(VALUE_SEPARATOR) }.join(PAIR_SEPARATOR)
        end
      end
    end
  end
end
