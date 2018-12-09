# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        module Types
          module Postgres
            TYPES = {
              bignum: Sql::TYPES[:bignum].meta(native_type: "bigint"),
              decimal: Sql::TYPES[:decimal].meta(column_type: :decimal, native_type: ->(meta) { "numeric(#{meta[:size][0]},#{meta[:size][1]})" }),
              integer: Sql::TYPES[:integer].meta(native_type: "integer"),
              string: Sql::TYPES[:string].meta(native_type: "text"),
              text: Sql::TYPES[:text].meta(column_type: :string),

              json: Pakyow::Data::Types.Constructor(:json) { |value|
                Sequel.pg_json(value)
              }.meta(mapping: :json, database_type: :json)
            }.freeze
          end

          module SQLite
            TYPES = {
              bignum: Sql::TYPES[:bignum].meta(native_type: "bigint"),
              decimal: Sql::TYPES[:decimal].meta(column_type: :decimal, native_type: ->(meta) { "numeric(#{meta[:size][0]}, #{meta[:size][1]})" }),
              integer: Sql::TYPES[:integer].meta(native_type: "integer"),
              string: Sql::TYPES[:string].meta(native_type: "varchar(255)"),
              text: Sql::TYPES[:text].meta(column_type: :string),

              # Used indirectly for migrations to override the column type (since
              # sqlite doesn't support bignum as a primary key).
              #
              pk_bignum: Sql::TYPES[:bignum].meta(column_type: :integer)
            }.freeze
          end

          module MySQL
            TYPES = {
              bignum: Sql::TYPES[:bignum].meta(native_type: "bigint(20)"),
              decimal: Sql::TYPES[:decimal].meta(column_type: :decimal, native_type: ->(meta) { "decimal(#{meta[:size][0]},#{meta[:size][1]})" }),
              integer: Sql::TYPES[:integer].meta(native_type: "int(11)"),
              string: Sql::TYPES[:string].meta(native_type: "varchar(255)"),
              text: Sql::TYPES[:text].meta(column_type: :string)
            }.freeze
          end
        end
      end
    end
  end
end
