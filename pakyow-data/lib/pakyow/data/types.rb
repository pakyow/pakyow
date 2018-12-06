# frozen_string_literal: true

require "dry-types"

module Pakyow
  module Data
    module Types
      include Dry::Types.module

      MAPPING = {
        boolean: Bool.meta(mapping: :boolean),
        date: Date.meta(mapping: :date),
        datetime: DateTime.meta(mapping: :datetime),
        decimal: Coercible::Decimal.meta(mapping: :decimal),
        float: Coercible::Float.meta(mapping: :float),
        integer: Coercible::Integer.meta(mapping: :integer),
        string: Coercible::String.meta(mapping: :string),
        time: Time.meta(mapping: :time)
      }.freeze

      def self.type_for(type, additional_types = {})
        if type.is_a?(Dry::Types::Type)
          type
        else
          type = type.to_sym
          additional_types.to_h.fetch(type) {
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
