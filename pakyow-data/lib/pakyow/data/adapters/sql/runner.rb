# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        class Runner
          def initialize(connection, migration_path)
            @connection, @migration_path = connection, migration_path
          end

          def disconnect!
            @connection.disconnect
          end

          def run!
            Pakyow.module_eval do
              unless singleton_class.instance_methods.include?(:migration)
                def self.migration(&block)
                  Sequel.migration(&block)
                end
              end
            end

            # Allows migrations to be defined with the nice mapping, then executed with the Sequel type.
            #
            local_types = @connection.types
            @connection.adapter.connection.define_singleton_method :type_literal do |column|
              if column[:type].is_a?(Symbol)
                begin
                  column[:type] = Data::Types.type_for(column[:type], local_types).meta[:database_type]
                rescue Pakyow::UnknownType
                end
              end

              super(column)
            end

            Sequel.extension :migration
            Sequel::Migrator.run(
              @connection.adapter.connection, @migration_path,
              allow_missing_migration_files: true
            )
          end
        end
      end
    end
  end
end
