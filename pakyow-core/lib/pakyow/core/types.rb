# frozen_string_literal: true

require "dry-types"

module Pakyow
  module Types
    include Dry::Types.module

    MAPPING = {
      string: Pakyow::Types::Coercible::String,
      boolean: Pakyow::Types::Form::Bool,
      date: Pakyow::Types::Form::Date,
      time: Pakyow::Types::Form::Time,
      datetime: Pakyow::Types::Form::Time,
      integer: Pakyow::Types::Form::Int,
      float: Pakyow::Types::Form::Float,
      decimal: Pakyow::Types::Form::Decimal
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
