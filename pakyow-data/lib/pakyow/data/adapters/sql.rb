# frozen_string_literal: true

require "sequel"

require "pakyow/support/deep_freeze"
require "pakyow/support/extension"

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/data/adapters/abstract"

module Pakyow
  module Data
    module Adapters
      class Sql < Abstract
        require "pakyow/data/adapters/sql/migrator"

        TYPES = {
          # overrides for default types
          boolean: Data::Types::MAPPING[:boolean].meta(default: false, database_type: :boolean, column_type: :boolean),
          date: Data::Types::MAPPING[:date].meta(database_type: :date),
          datetime: Data::Types::MAPPING[:datetime].meta(database_type: DateTime),
          decimal: Data::Types::MAPPING[:decimal].meta(database_type: BigDecimal, size: [10, 2]),
          float: Data::Types::MAPPING[:float].meta(database_type: :float),
          integer: Data::Types::MAPPING[:integer].meta(database_type: Integer),
          string: Data::Types::MAPPING[:string].meta(database_type: String),
          time: Data::Types::MAPPING[:time].meta(database_type: Time, column_type: :datetime),

          # sql-specific types
          file: Types.Constructor(Sequel::SQL::Blob).meta(mapping: :file, database_type: File, column_type: :blob),
          text: Types::Coercible::String.meta(mapping: :text, database_type: :text, column_type: :text, native_type: "text"),
          bignum: Types::Coercible::Integer.meta(mapping: :bignum, database_type: :Bignum)
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
          if connected?
            @connection.disconnect
            @connection = nil
          end
        end

        def connected?
          !@connection.nil?
        end

        def migratable?
          true
        end

        def auto_migratable?
          true
        end

        def finalized_attribute(attribute)
          if attribute.meta[:primary_key] || attribute.meta[:foreign_key]
            begin
              finalized_attribute = Data::Types.type_for(:"pk_#{attribute.meta[:mapping]}", Sql.types_for_adapter(@connection.opts[:adapter].to_sym)).dup

              if attribute.meta[:primary_key]
                finalized_attribute = finalized_attribute.meta(primary_key: attribute.meta[:primary_key])
              end

              if attribute.meta[:foreign_key]
                finalized_attribute = finalized_attribute.meta(foreign_key: attribute.meta[:foreign_key])
              end
            rescue Pakyow::UnknownType
              finalized_attribute = attribute.dup
            end
          else
            finalized_attribute = attribute.dup
          end

          finalized_meta = finalized_attribute.meta.dup

          if finalized_meta.include?(:mapping)
            finalized_meta[:migration_type] = finalized_meta[:mapping]
          end

          unless finalized_meta.include?(:migration_type)
            finalized_meta[:migration_type] = migration_type_for_attribute(attribute)
          end

          unless finalized_meta.include?(:column_type)
            finalized_meta[:column_type] = column_type_for_attribute(attribute)
          end

          unless finalized_meta.include?(:database_type)
            finalized_meta[:database_type] = database_type_for_attribute(attribute)
          end

          finalized_attribute.meta(**finalized_meta)
        end

        private

        def migration_type_for_attribute(attribute)
          attribute.meta[:database_type] || attribute.primitive
        end

        def column_type_for_attribute(attribute)
          attribute.primitive.to_s.downcase.to_sym
        end

        def database_type_for_attribute(attribute)
          attribute.primitive
        end

        class << self
          CONNECTION_TYPES = {
            postgres: "Types::Postgres",
            sqlite: "Types::SQLite",
            mysql2: "Types::MySQL"
          }.freeze

          def types_for_adapter(adapter)
            TYPES.dup.merge(const_get(CONNECTION_TYPES[adapter.to_sym])::TYPES)
          end

          using Support::Refinements::String::Normalization

          def build_opts(opts)
            database = if opts[:adapter] == "sqlite"
              opts[:path]
            else
              String.normalize_path(opts[:path])[1..-1]
            end

            opts[:path] = database
            opts
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
                :bignum
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
              bignum: Sql::TYPES[:bignum].meta(native_type: "bigint"),
              decimal: Sql::TYPES[:decimal].meta(column_type: :decimal),
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
              decimal: Sql::TYPES[:decimal].meta(column_type: :decimal),
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
              decimal: Sql::TYPES[:decimal].meta(column_type: :decimal, native_type: "decimal(10,2)"),
              integer: Sql::TYPES[:integer].meta(native_type: "int(11)"),
              string: Sql::TYPES[:string].meta(native_type: "varchar(255)"),
              text: Sql::TYPES[:text].meta(column_type: :string)
            }.freeze
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
              begin
                delete
              rescue Sequel::ForeignKeyConstraintViolation => error
                raise ConstraintViolation.build(error)
              end
            end
          end
        end
      end
    end
  end
end
