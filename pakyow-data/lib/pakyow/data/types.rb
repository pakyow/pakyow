# frozen_string_literal: true

module Pakyow
  module Data
    module Types
      BASE_CLASS = {
        sql: "ROM::SQL::Types"
      }.freeze

      # TODO: automatically include type extensions for particular types (e.g. postgres)
      # TODO: make sure there's a convenient way to store json data that's returned as a hash

      MAPPING = {
        serial: "Serial",
        string: "String",
        boolean: "Bool",
        date: "Date",
        time: "Time",
        datetime: "Time",
        integer: "Int",
        float: "Float",
        decimal: "Decimal",
        blob: "Blob"
      }.freeze

      def self.type_for(type, adapter)
        if type.is_a?(Dry::Types::Type)
          type
        else
          mapped_type = Kernel.const_get(BASE_CLASS.fetch(adapter)).const_get(MAPPING.fetch(type))

          if type == :boolean
            mapped_type = mapped_type.meta(db_type: "boolean")
          end
          if type == :blob
            mapped_type = mapped_type.meta(db_type: "blob")
          end
          if type == :decimal
            mapped_type = mapped_type.meta(db_type: "numeric(10, 2)")
          end

          mapped_type
        end
      rescue KeyError => error
        raise Pakyow.build_error(error, UnknownType, context: {
          type: type, types: MAPPING.keys
        })
      end
    end
  end
end
