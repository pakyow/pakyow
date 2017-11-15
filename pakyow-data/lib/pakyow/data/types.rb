module Pakyow
  module Data
    module Types
      BASE_CLASS = {
        memory: "ROM::Types".freeze,
        sql: "ROM::SQL::Types".freeze
      }.freeze

      MAPPING = {
        serial: "Serial",
        string: "String",
        boolean: "Bool",
        date: "Date",
        time: "Time",
        datetime: "DateTime"
      }

      def self.type_for(type, adapter)
        return type unless type.is_a?(Symbol)
        Kernel.const_get(BASE_CLASS.fetch(adapter)).const_get(MAPPING.fetch(type))
        # TODO: present a nicer error message
        # fail("unknown #{category} type #{type}")
      end
    end
  end
end
