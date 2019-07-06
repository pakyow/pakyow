# frozen_string_literal: true

require "pakyow/data/adapters/sql/migrator"

module Pakyow
  module Data
    module Adapters
      class Sql
        module Migrators
          # @api private
          class Automator < Migrator
            def associate_table(name, **, &block)
              alter_table(name, &block)
            end

            def alter_table(name, &block)
              @connection.adapter.connection.alter_table name do
                AlterTable.new(self).instance_exec(&block)
              end
            end

            def method_missing(name, *args, &block)
              @connection.adapter.connection.public_send(name, *args, &block)
            end

            private

            def type_for_attribute(attribute)
              attribute.meta[:database_type]
            end

            class AlterTable
              def initialize(table)
                @table = table
              end

              def drop_column(*)
                # Prevent columns from being dropped during auto migrate.
              end

              def method_missing(name, *args, &block)
                @table.public_send(name, *args, &block)
              end
            end
          end
        end
      end
    end
  end
end
