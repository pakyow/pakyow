# frozen_string_literal: true

require "uri"
require "sequel"

require "pakyow/support/class_state"

module Pakyow
  module Data
    class Migrator
      def initialize(adapter_type:, connection_name:, connection_opts: {})
        @adapter_type, @connection_name, @connection_opts = adapter_type, connection_name, connection_opts
        @connection, @global_connection = nil
      end

      def connection
        @connection ||= Connection.new(opts: @connection_opts, type: @adapter_type, name: @connection_name)
      end

      def global_connection
        @global_connection ||= create_global_connection
      end

      def disconnect!
        if @connection
          @connection.disconnect
        end

        yield if block_given?

        if @global_connection
          @global_connection.disconnect
        end
      end

      def migrate!
        if migrations_to_run? && sources.any?
          sources.first.const_get(:Migrator).new(sources, @connection).run!(migration_path)
        end
      end

      def auto_migrate!
        if sources.any?
          sources.first.const_get(:Migrator).new(sources, @connection).auto_migrate!
        end
      end

      def finalize!
        if sources.any?
          sources.first.const_get(:Migrator).new(sources, @connection).finalize!.each do |filename, content|
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
      end

      private

      def sources
        Pakyow.apps.reject(&:rescued?).flat_map { |app| app.state(:source) }.select { |source|
          connection.name == source.connection && connection.type == source.adapter
        }
      end

      def migrations
        Dir.glob(File.join(migration_path, "*.rb"))
      end

      def migrations_to_run?
        migrations.count > 0
      end

      def migration_path
        File.join(Pakyow.config.data.migration_path, "#{@adapter_type}/#{@connection_name}")
      end

      def track_exported_migrations
        initial_migrations = migrations
        yield
        migrations - initial_migrations
      end

      extend Support::ClassState
      class_state :migrators, default: []
      class_state :adapters, default: [], inheritable: true

      class << self
        def inherited(subclass)
          @migrators << subclass
        end

        def migrates(*adapters)
          @adapters = adapters
        end

        def migrator_for_adapter(adapter)
          @migrators.find { |migrator|
            migrator.adapters.include?(adapter.to_sym)
          }
        end

        def with_connection(connection)
          allocate.tap do |instance|
            instance.instance_variable_set(:@connection, connection)
            instance.instance_variable_set(:@adapter_type, connection.type)
            instance.instance_variable_set(:@connection_name, connection.name)
            instance.instance_variable_set(:@connection_opts, connection.opts)
          end
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

          if migrator_class = Pakyow::Data::Migrator.migrator_for_adapter(connection_opts[:adapter])
            migrator_class.new(
              adapter_type: adapter,
              connection_name: connection,
              connection_opts: connection_opts
            )
          else
            # FIXME: make this a nice error
            raise "Unknown migrator for database type `#{connection_opts[:adapter]}'"
          end
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
