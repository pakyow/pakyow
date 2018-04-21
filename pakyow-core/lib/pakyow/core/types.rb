# frozen_string_literal: true

require "dry-types"

module Pakyow
  module Types
    include Dry::Types.module

    MAPPING = {
      string: Coercible::String,
      boolean: Form::Bool,
      date: Form::Date,
      time: Form::Time,
      datetime: Form::Time,
      integer: Form::Int,
      float: Form::Float,
      decimal: Form::Decimal
    }.freeze

    def self.type_for(type)
      if type.is_a?(Dry::Types::Type)
        type
      else
        MAPPING.fetch(type.to_sym)
      end
    rescue KeyError => error
      raise Pakyow.build_error(error, UnknownType, context: {
        type: type, types: MAPPING.keys
      })
    end
  end
end
