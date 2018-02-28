# frozen_string_literal: true

module Pakyow
  module Data
    module Types
      BASE_CLASS = {
        input: "ROM::Types::Form",
        sql: "ROM::SQL::Types"
      }.freeze

      # TODO: automatically include type extensions for particular types (e.g. postgres)
      # TODO: make sure there's a convenient way to store json data that's returned as a hash

      MAPPING = {
        serial: "Serial",
        # TODO: this causes issues with inputs, because it doesn't return a type object but String
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
        return type unless type.is_a?(Symbol)
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
        # TODO: present a nicer error message
        # fail("unknown #{category} type #{type}")
      end
    end
  end
end
