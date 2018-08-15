# frozen_string_literal: true

require "dry-types"

module Pakyow
  module Types
    include Dry::Types.module

    MAPPING = {
      string: Coercible::String,
      boolean: Params::Bool,
      date: Params::Date,
      time: Params::Time,
      datetime: Params::Time,
      integer: Params::Integer,
      float: Params::Float,
      decimal: Params::Decimal
    }.freeze

    def self.type_for(type)
      if type.is_a?(Dry::Types::Type)
        type
      else
        MAPPING.fetch(type.to_sym)
      end
    rescue KeyError => error
      raise UnknownType.build(error, context: {
        type: type, types: MAPPING.keys
      })
    end
  end
end
