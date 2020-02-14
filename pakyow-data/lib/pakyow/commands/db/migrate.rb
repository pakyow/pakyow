# frozen_string_literal: true

Pakyow.command :db, :migrate, boot: false do
  describe "Migrate a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  action do
    require "pakyow/data/migrator"

    migrator = Pakyow::Data::Migrator.connect(
      adapter: @adapter, connection: @connection
    )

    migrator.migrate!
    migrator.disconnect!
  end
end
