# frozen_string_literal: true

require "erb"

require "sequel"

require "pakyow/support/deep_freeze"
require "pakyow/support/extension"

require "pakyow/data/adapters/abstract"

module Pakyow
  module Data
    module Adapters
      class Sql < Abstract
        TYPES = {
          # overrides for default types
          boolean: Types::Bool.meta(column_type: TrueClass, db_type: :boolean),
          datetime: Types::DateTime.meta(db_type: :datetime),
          decimal: Types::Coercible::Decimal.meta(column_type: BigDecimal, size: [10, 2]),

          # sql-specific types
          file: Types.Constructor(Sequel::SQL::Blob).meta(column_type: File),
          text: Types::String.meta(text: true)
        }.freeze

        extend Support::DeepFreeze
        unfreezable :connection

        attr_reader :connection

        DEFAULT_EXTENSIONS = {
          postgres: %i(pg_json)
        }.freeze

        def initialize(opts, logger: nil)
          @connection = Sequel.connect(
            adapter: opts[:adapter],
            database: opts[:path],
            host: opts[:host],
            port: opts[:port],
            user: opts[:user],
            password: opts[:password],
            logger: logger
          )

          DEFAULT_EXTENSIONS[opts[:adapter].to_sym].to_a.each do |extension|
            @connection.extension extension
          end
        rescue Sequel::AdapterNotFound => e
          puts e

          # TODO: handle missing gems
        rescue Sequel::DatabaseConnectionError => e
          puts e

          # TODO: handle failed connections
          #
          # maybe by raising a connection error that Pakyow::Data::Connection handles
          # by printing out a trace or something... it's important to communicate but
          # could also be handled (e.g. in the case you're running db:create)
          # there's a balance to strike here I think
        end

        def dataset_for_source(source)
          @connection[source.dataset_table]
        end

        def result_for_attribute_value(attribute, value, source)
          source.where(attribute => value)
        end

        def restrict_to_attribute(attribute, source)
          source.select(attribute)
        end

        def transaction(&block)
          @connection.transaction do
            begin
              block.call
            rescue Rollback
              raise Sequel::Rollback
            end
          end
        end

        def disconnect
          @connection.disconnect if connected?
        end

        def connected?
          !@connection.nil?
        end

        def migratable?
          true
        end

        def needs_migration?(source)
          Differ.new(connection: @connection, source: source).any?
        end

        def migrate!(migration_path)
          Pakyow.module_eval do
            unless singleton_class.instance_methods.include?(:migration)
              def self.migration(&block)
                Sequel.migration(&block)
              end
            end
          end

          Sequel.extension :migration
          Sequel::Migrator.run(@connection, migration_path)
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

        def finalize_migration!(source)
          differ = Differ.new(connection: @connection, source: source)

          if differ.exists?
            if differ.changes?
              template = <<~TEMPLATE
                change do
                  alter_table <%= differ.table_name.inspect %> do
                    <%- differ.attributes_to_add.each do |attribute_name, attribute_type| -%>
                    <%- if attribute_type.meta[:primary_key] -%>
                    add_primary_key <%= attribute_name.inspect %>
                    <%- elsif attribute_type.meta[:foreign_key] -%>
                    add_foreign_key <%= attribute_name.inspect %>, <%= attribute_type.meta[:foreign_key].inspect %>, type: <%= attribute_type.meta[:column_type].inspect %>
                    <%- else -%>
                    add_column <%= attribute_name.inspect %>, <%= attribute_type.meta[:column_type].inspect %><%= column_opts_string_for_attribute_type(attribute_type) %>
                    <%- end -%>
                    <%- end -%>
                    <%- differ.columns_to_remove.keys.each do |column_name| -%>
                    drop_column <%= column_name.inspect %>
                    <%- end -%>
                    <%- differ.column_types_to_change.each do |column_name, column_type| -%>
                    set_column_type <%= column_name.inspect %>, <%= column_type.inspect %>
                    <%- end -%>
                  end
                end
              TEMPLATE

              return :change, ERB.new(template, nil, "%<>-").result(binding)
            end
          else
            template = <<~TEMPLATE
              change do
                create_table <%= differ.table_name.inspect %> do
                  <%- differ.attributes.each do |attribute_name, attribute_type| -%>
                  <%- if attribute_type.meta[:primary_key] -%>
                  primary_key <%= attribute_name.inspect %>
                  <%- elsif attribute_type.meta[:foreign_key] -%>
                  foreign_key <%= attribute_name.inspect %>, <%= attribute_type.meta[:foreign_key].inspect %>, type: <%= attribute_type.meta[:column_type].inspect %>
                  <%- else -%>
                  column <%= attribute_name.inspect %>, <%= attribute_type.meta[:column_type].inspect %><%= column_opts_string_for_attribute_type(attribute_type) %>
                  <%- end -%>
                  <%- end -%>
                end
              end
            TEMPLATE

            return :create, ERB.new(template, nil, "%<>-").result(binding)
          end
        end

        private

        def define_column_for_attribute(attribute_name, attribute_type, table)
          if attribute_type.meta[:primary_key]
            table.primary_key attribute_name, type: attribute_type.meta[:column_type]
          elsif attribute_type.meta[:foreign_key]
            table.foreign_key attribute_name, attribute_type.meta[:foreign_key], type: attribute_type.meta[:column_type]
          else
            table.column attribute_name, attribute_type.meta[:column_type], **column_opts_for_attribute_type(attribute_type)
          end
        end

        def add_column_for_attribute(attribute_name, attribute_type, table)
          table.add_column attribute_name, attribute_type.meta[:column_type], **column_opts_for_attribute_type(attribute_type)
        end

        def remove_column_by_name(column_name, table)
          table.drop_column column_name
        end

        def change_column_type(column_name, column_type, table)
          table.set_column_type column_name, column_type
        end

        ALLOWED_COLUMN_OPTS = %i(size text)
        def column_opts_for_attribute_type(attribute_type)
          {}.tap do |opts|
            ALLOWED_COLUMN_OPTS.each do |opt|
              if value = attribute_type.meta[opt]
                opts[opt] = value
              end
            end
          end
        end

        def column_opts_string_for_attribute_type(attribute_type)
          opts = column_opts_for_attribute_type(attribute_type)

          if opts.any?
            opts.each_with_object(String.new) { |(key, value), opts_string|
              opts_string << ", #{key}: #{value.inspect}"
            }
          else
            ""
          end
        end

        class << self
          CONNECTION_TYPES = {
            postgres: "Types::Postgres",
            sqlite: "Types::SQLite",
            mysql2: "Types::MySQL"
          }.freeze

          def types_for_connection(connection)
            connection_adapter = connection.adapter.connection.opts[:adapter]
            TYPES.dup.merge(const_get(CONNECTION_TYPES[connection_adapter.to_sym])::TYPES)
          end
        end

        # Diffs a data source with the table behind it.
        #
        class Differ
          def initialize(connection:, source:)
            @connection, @source = connection, source
          end

          def any?
            !exists? || changes?
          end

          def exists?
            @connection.table_exists?(table_name)
          end

          def changes?
            attributes_to_add.any? || columns_to_remove.any? || column_types_to_change.any?
          end

          def table_name
            @source.dataset_table
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
              self.attributes.each do |attribute_name, attribute_type|
                if found_column = schema.find { |column| column[0] == attribute_name }
                  column_name, column_info = found_column
                  unless column_info[:type] == attribute_type.meta[:db_type]
                    attributes[column_name] = attribute_type.meta[:db_type]
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

        module SourceExtension
          extend Support::Extension

          apply_extension do
            def sql
              __getobj__.sql
            end

            class_state :dataset_table, default: self.__object_name.name

            class << self
              def table(table_name)
                @dataset_table = table_name
              end

              def primary_key_type
                Pakyow::Data::Types::Coercible::Integer.meta(column_type: :Bignum)
              end
            end
          end
        end

        module DatasetMethods
          def to_a(dataset)
            dataset.all
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end

          def one(dataset)
            dataset.first
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end

          def count(dataset)
            dataset.count
          rescue Sequel::Error => error
            raise QueryError.build(error)
          end
        end

        module Types
          module Postgres
            TYPES = {
              json: Pakyow::Data::Types.Constructor(:json) { |value|
                Sequel.pg_json(value)
              }.meta(db_type: :json)
            }.freeze
          end

          module SQLite
            TYPES = {}.freeze
          end

          module MySQL
            TYPES = {}.freeze
          end
        end

        module Commands
          extend Support::Extension

          apply_extension do
            command :create, performs_create: true do |values|
              begin
                if inserted_primary_key = insert(values)
                  where(self.class.primary_key_field => inserted_primary_key)
                else
                  where(values)
                end
              rescue Sequel::UniqueConstraintViolation => error
                raise UniqueViolation.build(error)
              rescue Sequel::ForeignKeyConstraintViolation => error
                raise ConstraintViolation.build(error)
              end
            end

            command :update, performs_update: true do |values|
              __getobj__.select(self.class.primary_key_field).map { |result|
                result[self.class.primary_key_field]
              }.tap do
                begin
                  unless values.empty?
                    update(values)
                  end
                rescue Sequel::UniqueConstraintViolation => error
                  raise UniqueViolation.build(error)
                rescue Sequel::ForeignKeyConstraintViolation => error
                  raise ConstraintViolation.build(error)
                end
              end
            end

            command :delete, provides_dataset: false, performs_delete: true do
              delete
            end
          end
        end
      end
    end
  end
end
