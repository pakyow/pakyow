# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Data
      module Config
        extend Support::Extension

        apply_extension do
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
              setting :types, Pakyow::Data::Connection::SUPPORTED_CONNECTION_TYPES

              Pakyow::Data::Connection::SUPPORTED_CONNECTION_TYPES.each do |type|
                setting type, {}
              end
            end
          end
        end
      end
    end
  end
end
