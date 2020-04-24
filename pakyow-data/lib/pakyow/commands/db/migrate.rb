# frozen_string_literal: true

command :db, :migrate, boot: false do
  describe "Migrate a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  prelaunch :release do |command|
    Pakyow.data_connections.each do |adapter, connections|
      connections.each do |connection_name, connection|
        if connection.migratable? && connection_name != :memory
          command.call(adapter: adapter, connection: connection_name)
        end
      end
    end
  end

  action do
    Pakyow.setup(env: @env)

    require "pakyow/data/migrator"

    migrator = Pakyow::Data::Migrator.connect(
      adapter: @adapter, connection: @connection
    )

    migrator.migrate!
    migrator.disconnect!
  end
end
