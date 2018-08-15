# frozen_string_literal: true

require "dry-types"

module Pakyow
  module Data
    module Types
      include Dry::Types.module

      MAPPING = {
        boolean: Bool,
        date: Date,
        datetime: DateTime,
        decimal: Coercible::Decimal,
        float: Coercible::Float,
        integer: Coercible::Integer,
        string: Coercible::String,
        time: Time
      }.freeze

      def self.type_for(type, additional_types = {})
        if type.is_a?(Dry::Types::Type)
          type
        else
          type = type.to_sym
          additional_types.fetch(type) {
            MAPPING.fetch(type)
          }
        end
      rescue KeyError => error
        raise UnknownType.build(error, context: {
          type: type, types: MAPPING.keys
        })
      end
    end
  end
end
