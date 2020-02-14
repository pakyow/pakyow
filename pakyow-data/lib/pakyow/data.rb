# frozen_string_literal: true

require "pakyow"
require "pakyow/routing"

require "pakyow/data/connection"

Pakyow::Data::Connection.register_adapter :sql

require "pakyow/data/errors"
require "pakyow/data/framework"

require "pakyow/behavior/data/auto_migrate"
require "pakyow/behavior/data/connections"
require "pakyow/behavior/data/memory_db"

require "pakyow/validations/data/unique"

module Pakyow
  config.commands.paths << File.expand_path("../commands", __FILE__)

  include Behavior::Data::AutoMigrate
  include Behavior::Data::Connections
  include Behavior::Data::MemoryDB

  on "configure" do
    # We have to define these in a before configure hook since new types could be added.
    #
    configurable :data do
      configurable :connections do
        Pakyow::Data::Connection.adapter_types.each do |type|
          setting type, {}
        end
      end
    end
  end

  configurable :data do
    setting :default_adapter, :sql
    setting :default_connection, :default

    setting :silent, true
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
