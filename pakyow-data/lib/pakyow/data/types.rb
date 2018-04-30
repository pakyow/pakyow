# frozen_string_literal: true

require "dry-types"

module Pakyow
  module Data
    module Types
      include Dry::Types.module

      MAPPING = {
        integer: Coercible::Int,
        string: Coercible::String,
        float: Coercible::Float,
        decimal: Coercible::Decimal,
        date: Date,
        datetime: DateTime,
        time: Time,
        boolean: Bool
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
        raise Pakyow.build_error(error, UnknownType, context: {
          type: type, types: MAPPING.keys
        })
      end
    end
  end
end
