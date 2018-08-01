# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/core/framework"

require "pakyow/data/types"
require "pakyow/data/lookup"
require "pakyow/data/source"
require "pakyow/data/object"
require "pakyow/data/proxy"
require "pakyow/data/subscribers"
require "pakyow/data/errors"
require "pakyow/data/connection"
require "pakyow/data/container"

require "pakyow/data/sources/ephemeral"

module Pakyow
  module Data
    SUPPORTED_CONNECTION_TYPES = %i(sql)

    class Framework < Pakyow::Framework(:data)
      def boot
        if controller = app.const_get(:Controller)
          controller.class_eval do
            def data
              app.data
            end
          end
        end

        app.class_eval do
          stateful :source, Source
          stateful :object, Object

          # Autoload sources from the `sources` directory.
          #
          aspect :sources

          # Autoload objects from the `objects` directory.
          #
          aspect :objects

          # Data container object.
          #
          attr_reader :data

          after :initialize do
            @data = Lookup.new(
              containers: Pakyow.data_connections.values.each_with_object([]) { |connections, containers|
                connections.values.each do |connection|
                  containers << Container.new(
                    connection: connection,
                    sources: state_for(:source).select { |source|
                      connection.name == source.connection && connection.type == source.adapter
                    },
                    objects: state_for(:object)
                  )
                end
              },
              subscribers: Subscribers.new(
                self,
                Pakyow.config.data.subscriptions.adapter,
                Pakyow.config.data.subscriptions.adapter_settings.to_h
              )
            )
          end
        end
      end
    end

    Pakyow.module_eval do
      class_state :data_connections, default: {}

      class << self
        # @api private
        def connection(adapter, connection)
          adapter ||= Pakyow.config.data.default_adapter
          connection ||= Pakyow.config.data.default_connection
          unless connection_instance = Pakyow.data_connections.dig(adapter.to_sym, connection.to_sym)
            raise ArgumentError, "Unknown database connection named `#{connection}' for adapter `#{adapter}'"
          end

          connection_instance
        end
      end

      settings_for :data do
        setting :default_adapter, :sql
        setting :default_connection, :default

        setting :silent, true
        setting :auto_migrate, true
        setting :auto_migrate_always, [:memory]
        setting :migration_path, "./database/migrations"

        defaults :production do
          setting :auto_migrate, false
        end

        settings_for :subscriptions do
          setting :adapter, :memory
          setting :adapter_settings, {}

          defaults :production do
            setting :adapter, :redis
            setting :adapter_settings do
              @adapter_settings ||= Pakyow.config.redis.dup
            end
          end
        end

        settings_for :connections do
          SUPPORTED_CONNECTION_TYPES.each do |type|
            setting type, {}
          end
        end
      end

      after :setup do
        @data_connections = SUPPORTED_CONNECTION_TYPES.each_with_object({}) { |connection_type, connections|
          connections[connection_type] = Pakyow.config.data.connections.public_send(connection_type).each_with_object({}) { |(connection_name, connection_string), adapter_connections|
            extra_options = {}

            unless Pakyow.config.data.silent
              extra_options[:logger] = Pakyow.logger
            end

            adapter_connections[connection_name] = Connection.new(
              string: connection_string,
              type: connection_type,
              name: connection_name,
              **extra_options
            )
          }
        }

        @data_connections.each do |adapter, connections|
          connections.each do |connection_name, connection|
            if connection.migratable? && connection_name != :memory
              config.tasks.prelaunch << [:"db:migrate", { adapter: adapter, connection: connection_name }]
            end
          end
        end
      end

      after :boot do
        if Pakyow.config.data.auto_migrate || Pakyow.config.data.auto_migrate_always.any?
          require "pakyow/data/migrator"
          require "pakyow/data/migrators/mysql"
          require "pakyow/data/migrators/postgres"
          require "pakyow/data/migrators/sqlite"

          @data_connections.values.flat_map(&:values)
            .select(&:connected?)
            .select(&:auto_migrate?)
            .select { |connection|
              Pakyow.config.data.auto_migrate || Pakyow.config.data.auto_migrate_always.include?(connection.name)
            }.each do |auto_migratable_connection|
            migrator = Pakyow::Data::Migrator.with_connection(auto_migratable_connection)
            migrator.auto_migrate!
          end
        end
      end

      config.tasks.paths << File.expand_path("../tasks", __FILE__)
    end
  end
end
