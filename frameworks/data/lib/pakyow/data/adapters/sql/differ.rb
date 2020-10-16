# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        # @api private
        class Differ
          def initialize(connection:, source:, attributes: source.attributes)
            @connection, @source, @attributes = connection, source, attributes
          end

          def exists?
            raw_connection.table_exists?(table_name)
          end

          def changes?
            attributes_to_add.any? || columns_to_remove.any? || column_types_to_change.any?
          end

          def table_name
            @source.dataset_table
          end

          def attributes
            Hash[@attributes.map { |attribute_name, attribute|
              [attribute_name, @connection.adapter.finalized_attribute(attribute)]
            }]
          end

          def attributes_to_add
            attributes = {}

            self.attributes.each do |attribute_name, attribute_type|
              unless schema.find { |column| column[0] == attribute_name }
                attributes[attribute_name] = attribute_type
              end
            end

            attributes
          end

          def columns_to_remove
            columns = {}

            schema.each do |column_name, column_info|
              unless @source.attributes.keys.find { |attribute_name| attribute_name == column_name }
                columns[column_name] = column_info
              end
            end

            columns
          end

          def column_types_to_change
            attributes = {}

            self.attributes.each do |attribute_name, attribute_type|
              if (found_column = schema.find { |column| column[0] == attribute_name })
                column_name, column_info = found_column
                unless column_info[:type] == attribute_type.meta[:column_type] && (!attribute_type.meta.include?(:native_type) || column_info[:db_type] == attribute_type.meta[:native_type])
                  attributes[column_name] = attribute_type.meta[:migration_type]
                end
              end
            end

            attributes
          end

          private

          def raw_connection
            @connection.adapter.connection
          end

          def schema
            raw_connection.schema(table_name)
          end
        end
      end
    end
  end
end
