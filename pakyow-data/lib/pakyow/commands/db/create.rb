# frozen_string_literal: true

command :db, :create, boot: false do
  describe "Create a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  action do
    require "pakyow/data/migrator"

    migrator = Pakyow::Data::Migrator.connect_global(
      adapter: @adapter, connection: @connection
    )

    migrator.create!
    migrator.disconnect!
  end
end
