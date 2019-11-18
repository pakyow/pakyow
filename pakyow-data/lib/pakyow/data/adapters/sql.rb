# frozen_string_literal: true

require "sequel"

require "pakyow/support/deep_freeze"
require "pakyow/support/extension"

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/data/adapters/base"

module Pakyow
  module Data
    module Adapters
      # @api private
      class Sql < Base
        require "pakyow/data/adapters/sql/commands"
        require "pakyow/data/adapters/sql/dataset_methods"
        require "pakyow/data/adapters/sql/migrator"
        require "pakyow/data/adapters/sql/runner"
        require "pakyow/data/adapters/sql/source_extension"

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
          file: Data::Types.Constructor(Sequel::SQL::Blob).meta(mapping: :file, database_type: File, column_type: :blob),
          text: Data::Types::Coercible::String.meta(mapping: :text, database_type: :text, column_type: :text, native_type: "text"),
          bignum: Data::Types::Coercible::Integer.meta(mapping: :bignum, database_type: :Bignum)
        }.freeze

        require "pakyow/data/adapters/sql/types"

        attr_reader :connection

        DEFAULT_EXTENSIONS = %i(
          connection_validator
        ).freeze

        DEFAULT_ADAPTER_EXTENSIONS = {
          postgres: %i(
            pg_json
          ).freeze
        }.freeze

        extend Support::DeepFreeze
        insulate :connection

        def initialize(opts, logger: nil)
          @opts, @logger = opts, logger
          connect
        end

        def qualify_attribute(attribute, source)
          Sequel.qualify(source.class.dataset_table, attribute)
        end

        def alias_attribute(attribute, as)
          Sequel.as(attribute, as)
        end

        def dataset_for_source(source)
          @connection[source.dataset_table]
        end

        def result_for_attribute_value(attribute, value, source)
          source.where(attribute => value)
        end

        def restrict_to_source(restrict_to_source, source, *additional_fields)
          source.select.qualify(
            restrict_to_source.class.dataset_table
          ).select_append(
            *additional_fields
          )
        end

        def restrict_to_attribute(attribute, source)
          source.select(*attribute)
        end

        def merge_results(left_column_name, right_column_name, mergeable_source, merge_into_source)
          merge_into_source.tap do
            merge_into_source.__setobj__(
              merge_into_source.join(
                mergeable_source.class.dataset_table, left_column_name => right_column_name
              )
            )
          end
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

        def connect
          @connection = Sequel.connect(
            adapter: @opts[:adapter],
            database: @opts[:path],
            host: @opts[:host],
            port: @opts[:port],
            user: @opts[:user],
            password: @opts[:password],
            logger: @logger
          )

          (DEFAULT_EXTENSIONS + DEFAULT_ADAPTER_EXTENSIONS[@opts[:adapter].to_s.to_sym].to_a).each do |extension|
            @connection.extension extension
          end

          if @opts.include?(:timeout)
            @connection.pool.connection_validation_timeout = @opts[:timeout].to_i
          end
        rescue Sequel::AdapterNotFound => error
          raise MissingAdapter.build(error)
        rescue Sequel::DatabaseConnectionError => error
          raise ConnectionError.build(error)
        end

        def disconnect
          if connected?
            @connection.disconnect
          end
        end

        def connected?
          @connection.opts[:adapter] == "sqlite" || @connection.test_connection
        rescue
          false
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

          finalized_meta.each do |key, value|
            finalized_meta[key] = case value
            when Proc
              if value.arity == 1
                value.call(finalized_meta)
              else
                value.call
              end
            else
              value
            end
          end

          finalized_attribute.meta(finalized_meta)
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
              if opts[:host]
                File.join(opts[:host], opts[:path])
              else
                opts[:path]
              end
            else
              String.normalize_path(opts[:path])[1..-1]
            end

            opts[:path] = database
            opts
          end
        end
      end
    end
  end
end
