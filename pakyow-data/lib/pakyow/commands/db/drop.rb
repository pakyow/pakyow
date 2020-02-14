# frozen_string_literal: true

Pakyow.command :db, :drop, boot: false do
  describe "Drop a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  action do
    require "pakyow/data/migrator"

    begin
      Pakyow.connection(adapter, connection).disconnect
    rescue ArgumentError
    end

    migrator = Pakyow::Data::Migrator.connect_global(
      adapter: @adapter, connection: @connection
    )

    migrator.drop!
    migrator.disconnect!
  end
end
