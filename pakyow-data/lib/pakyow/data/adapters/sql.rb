# frozen_string_literal: true

require "forwardable"
require "erb"

require "sequel"

require "pakyow/support/deep_freeze"

require "pakyow/data/adapters/abstract"

module Pakyow
  module Data
    module Adapters
      class Sql < Abstract
        TYPES = {
          integer: Types::Coercible::Int,
          string: Types::Coercible::String,
          float: Types::Coercible::Float,
          decimal: Types::Coercible::Decimal.meta(column_type: BigDecimal),
          date: Types::Date,
          datetime: Types::DateTime.meta(db_type: :datetime),
          time: Types::Time,
          boolean: Types::Bool.meta(column_type: TrueClass),
          serial: Types::Int.meta(primary_key: true)
        }.freeze

        extend Support::DeepFreeze
        unfreezable :connection

        extend Forwardable
        def_delegators :@connection, :disconnect

        def initialize(opts)
          @connection = Sequel.connect(
            adapter: opts[:adapter],
            database: opts[:path],
            host: opts[:host],
            user: opts[:user],
            password: opts[:password]
          )
        rescue Sequel::AdapterNotFound => e
          puts e

          # TODO: handle missing gems
        end

        def dataset_for_source(source)
          @connection[source.plural_name]
        end

        def migratable?
          true
        end

        def auto_migrate!(source)
          differ = Differ.new(connection: @connection, source: source)

          if differ.exists?
            if differ.changes?
              local_self = self
              @connection.alter_table differ.table_name do
                differ.attributes_to_add.each do |attribute_name, attribute_type|
                  local_self.send(:add_column_for_attribute, attribute_name, attribute_type, self)
                end

                differ.columns_to_remove.keys.each do |column_name|
                  local_self.send(:remove_column_by_name, column_name, self)
                end

                differ.column_types_to_change.each do |column_name, column_type|
                  local_self.send(:change_column_type, column_name, column_type, self)
                end
              end
            end
          else
            local_self = self
            @connection.create_table differ.table_name do
              differ.attributes.each do |attribute_name, attribute_type|
                local_self.send(:define_column_for_attribute, attribute_name, attribute_type, self)
              end
            end
          end
        end

        def needs_migration?(source)
          differ = Differ.new(connection: @connection, source: source)
          !differ.exists? || differ.changes?
        end

        def finalize_migration!(source)
          differ = Differ.new(connection: @connection, source: source)

          if differ.exists?
            if differ.changes?
              template = <<~TEMPLATE
                change do
                  alter_table <%= differ.table_name.inspect %> do
                    <% differ.attributes_to_add.each do |attribute_name, attribute_type| %>
                    add_column <%= attribute_name.inspect %>, <%= attribute_type.meta[:column_type].inspect %>
                    <% end %>

                    <% differ.columns_to_remove.keys.each do |column_name| %>
                    drop_column <%= column_name.inspect %>
                    <% end %>

                    <% differ.column_types_to_change.each do |column_name, column_type| %>
                    set_column_type <%= column_name.inspect %>, <%= column_type.inspect %>
                    <% end %>
                  end
                end
              TEMPLATE

              ERB.new(template, nil, "%<>-").result(binding)
            end
          else
            template = <<~TEMPLATE
              change do
                create_table <%= differ.table_name.inspect %> do
                  <%- differ.attributes.each do |attribute_name, attribute_type| -%>
                  <%- if attribute_type.meta[:primary_key] -%>
                  primary_key <%= attribute_name.inspect %>
                  <%- else -%>
                  column <%= attribute_name.inspect %>, <%= attribute_type.meta[:db_type].inspect %>
                  <%- end -%>
                  <%- end -%>
                end
              end
            TEMPLATE

            ERB.new(template, nil, "%<>-").result(binding)
          end
        end

        private

        def define_column_for_attribute(attribute_name, attribute_type, table)
          if attribute_type.meta[:primary_key]
            table.primary_key attribute_name
          else
            table.column attribute_name, attribute_type.meta[:db_type]
          end
        end

        def add_column_for_attribute(attribute_name, attribute_type, table)
          table.add_column attribute_name, attribute_type.meta[:column_type]
        end

        def remove_column_by_name(column_name, table)
          table.drop_column column_name
        end

        def change_column_type(column_name, column_type, table)
          table.set_column_type column_name, column_type
        end

        def column_opts_for_attribute_type(attribute_type)
          # TODO: hook this up for default, nullable, others in the future

          {}
        end

        # Diffs a data source with the table behind it.
        #
        class Differ
          def initialize(connection:, source:)
            @connection, @source = connection, source
          end

          def exists?
            @connection.table_exists?(table_name)
          end

          def changes?
            attributes_to_add.any? || columns_to_remove.any? || column_types_to_change.any?
          end

          def table_name
            @source.plural_name
          end

          def attributes
            Hash[@source.attributes.map { |attribute_name, attribute_type|
              finalized_type = attribute_type.dup
              finalized_meta = finalized_type.meta.dup
              finalized_meta[:column_type] ||= column_type_for_attribute_type(attribute_type)
              finalized_meta[:db_type] ||= column_db_type_for_attribute_type(attribute_type)
              [attribute_name, finalized_type.meta(**finalized_meta)]
            }]
          end

          def attributes_to_add
            {}.tap { |attributes|
              self.attributes.each do |attribute_name, attribute_type|
                unless schema.find { |column| column[0] == attribute_name }
                  attributes[attribute_name] = attribute_type
                end
              end
            }
          end

          def columns_to_remove
            {}.tap { |columns|
              schema.each do |column_name, column_info|
                unless @source.attributes.keys.find { |attribute_name| attribute_name == column_name }
                  columns[column_name] = column_info
                end
              end
            }
          end

          def column_types_to_change
            {}.tap { |attributes|
              attributes.each do |attribute_name, attribute_type|
                if column = schema.find { |column| column[0] == attribute_name }
                  column_name, column_info = column

                  unless column_info[:type] == attribute_type.meta(:db_type)
                    attributes[column_name] = attribute_type.meta(:db_type)
                  end
                end
              end
            }
          end

          private

          def schema
            @connection.schema(table_name)
          end

          def column_type_for_attribute_type(attribute_type)
            attribute_type.primitive
          end

          def column_db_type_for_attribute_type(attribute_type)
            attribute_type.primitive.to_s.downcase.to_sym
          end
        end
      end
    end
  end
end
