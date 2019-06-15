# frozen_string_literal: true

require "uri"
require "sequel"

require "pakyow/support/inflector"

module Pakyow
  module Data
    class Migrator
      def initialize(connection)
        @connection = connection
      end

      IVARS_TO_DISCONNECT = %i(@runner @migrator).freeze

      def disconnect!
        IVARS_TO_DISCONNECT.each do |ivar|
          if instance_variable_defined?(ivar) && value = instance_variable_get(ivar)
            value.disconnect!
          end
        end

        @connection.disconnect
      end

      def create!
        migrator.create!
        disconnect!

        # Recreate the connection, since we just created the database it's supposed to connect to.
        #
        @connection = Connection.new(
          opts: @connection.opts,
          type: @connection.type,
          name: @connection.name
        )
      end

      def drop!
        migrator.drop!
      end

      def migrate!
        if migrations_to_run?
          runner.run!
        end
      end

      def auto_migrate!
        migrator.auto_migrate!
      end

      def finalize!
        migrator.finalize!.each do |filename, content|
          FileUtils.mkdir_p(migration_path)

          File.open(File.join(migration_path, filename), "w+") do |file|
            file.write <<~CONTENT
              Pakyow.migration do
              #{content.to_s.split("\n").map { |line| "  #{line}" }.join("\n")}
              end
            CONTENT
          end
        end
      end

      private

      def migrator
        @migrator = self.class.migrator_for_adapter(Support.inflector.classify(@connection.type), :Migrator).new(
          @connection, sources: sources
        )
      end

      def runner
        @runner = self.class.migrator_for_adapter(Support.inflector.classify(@connection.type), :Runner).new(
          @connection, migration_path
        )
      end

      def sources
        Pakyow.apps.reject(&:rescued?).flat_map { |app|
          app.data.containers.flat_map(&:sources).concat(
            app.plugs.flat_map { |plug|
              plug.data.containers.flat_map(&:sources)
            }
          )
        }.select { |source|
          source.connection == @connection.name && source.adapter == @connection.type
        }
      end

      def migrations
        Dir.glob(File.join(migration_path, "*.rb"))
      end

      def migrations_to_run?
        migrations.count > 0
      end

      def migration_path
        File.join(Pakyow.config.data.migration_path, "#{@connection.type}/#{@connection.name}")
      end

      def track_exported_migrations
        initial_migrations = migrations
        yield
        migrations - initial_migrations
      end

      class << self
        def migrator_for_adapter(adapter, type = :Migrator)
          Adapters.const_get(Support.inflector.camelize(adapter)).const_get(type)
        end

        def connect(adapter:, connection:, connection_overrides: {})
          adapter = if adapter
            adapter.to_sym
          else
            Pakyow.config.data.default_adapter
          end

          connection = if connection
            connection.to_sym
          else
            Pakyow.config.data.default_connection
          end

          connection_opts = Connection.parse_connection_string(
            Pakyow.config.data.connections.send(adapter)[connection]
          )

          merge_connection_overrides!(connection_opts, connection_overrides)
          new(Connection.new(opts: connection_opts, type: adapter, name: connection))
        end

        def connect_global(adapter:, connection:, connection_overrides: {})
          adapter = if adapter
            adapter.to_sym
          else
            Pakyow.config.data.default_adapter
          end

          connection = if connection
            connection.to_sym
          else
            Pakyow.config.data.default_connection
          end

          connection_opts = Connection.parse_connection_string(
            Pakyow.config.data.connections.send(adapter)[connection]
          )

          merge_connection_overrides!(connection_opts, connection_overrides)
          globalize_connection_opts!(adapter, connection_opts)

          connect(
            adapter: adapter,
            connection: connection,
            connection_overrides: connection_opts
          )
        end

        def globalize_connection_opts!(adapter, connection_opts)
          migrator_for_adapter(adapter).globalize_connection_opts!(connection_opts)
        end

        def merge_connection_overrides!(connection_opts, connection_overrides)
          connection_overrides.each do |key, value|
            key = key.to_sym
            connection_opts[key] = if value.is_a?(Proc)
              value.call(connection_opts[key])
            else
              value
            end
          end
        end
      end
    end
  end
end
