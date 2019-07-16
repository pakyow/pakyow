# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Finalize a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :finalize, [:adapter, :connection] do |_, args|
    unless Pakyow.booted?
      Pakyow.boot(unsafe: true)
    end

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
