# frozen_string_literal: true

Pakyow.command :db, :finalize, boot: false do
  describe "Finalize a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  action do
    # We need to boot so that containers are available, but don't want to auto migrate.
    #
    Pakyow.config.data.auto_migrate = false; Pakyow.boot

    require "pakyow/data/migrator"

    opts = {
      adapter: @adapter,
      connection: @connection,
      connection_overrides: {
        path: -> (connection_path) {
          "#{connection_path}-migrator"
        }
      }
    }

    # Use a global connection for creating the database.
    #
    global_migrator = Pakyow::Data::Migrator.connect_global(opts)

    # Create the migrator database unless it exists.
    #
    global_migrator.create!

    # Use a normal migrator for migrating.
    #
    migrator = Pakyow::Data::Migrator.connect(opts)

    # Run the existing migrations on it.
    #
    migrator.migrate!

    # Create migrations for unmigrated schema.
    #
    migrator.finalize!

    # Disconnect.
    #
    migrator.disconnect!

    # Drop the migrator database.
    #
    global_migrator.drop!

    # Disconnect the migrator database.
    #
    global_migrator.disconnect!
  end
end
