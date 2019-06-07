# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Data
      module Config
        extend Support::Extension

        apply_extension do
          on "configure" do
            # We have to define these in a before configure hook since new types could be added.
            #
            Pakyow.config.data.connections.instance_eval do
              Pakyow::Data::Connection.adapter_types.each do |type|
                setting type, {}
              end
            end
          end

          configurable :data do
            setting :default_adapter, :sql
            setting :default_connection, :default

            setting :silent, false
            setting :auto_migrate, true
            setting :auto_migrate_always, [:memory]
            setting :migration_path, "./database/migrations"

            defaults :production do
              setting :auto_migrate, false
            end

            configurable :subscriptions do
              setting :adapter, :memory
              setting :adapter_settings, {}

              defaults :production do
                setting :adapter, :redis
                setting :adapter_settings do
                  Pakyow.config.redis.to_h
                end
              end
            end

            configurable :connections do
            end
          end
        end
      end
    end
  end
end
