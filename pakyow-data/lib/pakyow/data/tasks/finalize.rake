# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Finalize a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :finalize, [:adapter, :connection] do |_, args|
    Pakyow.boot

    opts = {
      adapter: args[:adapter],
      connection: args[:connection],
      connection_overrides: {
        path: -> (connection_path) {
          "#{connection_path}-migrator"
        }
      }
    }

    # Use a global connection for creating the database.
    #
    migrator = Pakyow::Data::Migrator.connect_global(opts)

    # Create the migrator database unless it exists.
    #
    migrator.create!

    # Done with global, disconnect.
    #
    migrator.disconnect!

    # Use a normal migrator for migrating.
    #
    migrator = Pakyow::Data::Migrator.connect(opts)

    # Run the existing migrations on it.
    #
    migrator.migrate!

    # Create migrations for unmigrated schema.
    #
    migrator.finalize!

    # Drop the migrator database.
    #
    migrator.drop!

    # Disconnect everything.
    #
    migrator.disconnect!
  end
end
