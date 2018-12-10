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
        @migrator = Adapters.const_get(Support.inflector.classify(@connection.type)).const_get(:Migrator).new(
          @connection, sources: sources
        )
      end

      def runner
        @runner = Adapters.const_get(Support.inflector.classify(@connection.type)).const_get(:Runner).new(
          @connection, migration_path
        )
      end

      def sources
        Pakyow.apps.reject(&:rescued?).flat_map { |app| app.state(:source) }.select { |source|
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
        def migrator_for_adapter(adapter)
          Adapters.const_get(Support.inflector.camelize(adapter)).const_get(:Migrator)
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

          connection_opts = Pakyow.connection(adapter, connection).opts.dup

          connection_overrides.each do |key, value|
            key = key.to_sym
            connection_opts[key] = if value.is_a?(Proc)
              value.call(connection_opts[key])
            else
              value
            end
          end

          new(Connection.new(opts: connection_opts, type: adapter, name: connection))
        end

        def parse_connection_string(connection_string)
          # FIXME: handle bad uri (ArgumentError is raised)
          uri = URI(connection_string)

          {
            adapter: uri.scheme,
            host: uri.host,
            database: uri.path.gsub("/", ""),
            user: uri.user,
            password: uri.password
          }
        end
      end
    end
  end
end
