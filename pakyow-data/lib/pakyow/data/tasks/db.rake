# frozen_string_literal: true

require "pakyow/data/migrator"
require "pakyow/data/migrators/mysql"
require "pakyow/data/migrators/postgres"
require "pakyow/data/migrators/sqlite"

namespace :db do
  desc "Sets up the database from scratch"
  task :setup, [:adapter, :connection] do |_, args|
    %w[
      db:create
      db:migrate
    ].each do |task|
      Rake::Task[task].invoke(args[:adapter], args[:connection])
    end
  end

  desc "Resets the database"
  task :reset, [:adapter, :connection] do |_, args|
    %w[
      db:drop
      db:setup
    ].each do |task|
      Rake::Task[task].invoke(args[:adapter], args[:connection])
    end
  end

  desc "Creates the database"
  task :create, [:adapter, :connection] do |_, args|
    migrator = Pakyow::Data::Migrator.establish(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.create!
    migrator.disconnect!
  end

  desc "Drops the database"
  task :drop, [:adapter, :connection] do |_, args|
    if connection = Pakyow.connection(args[:adapter], args[:connection])
      connection.disconnect
    end

    migrator = Pakyow::Data::Migrator.establish(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.disconnect!
    migrator.drop!
  end

  desc "Runs database migrations"
  task :migrate, [:adapter, :connection] do |_, args|
    if Pakyow.config.data.auto_migrate
      # FIXME: make this a nice error
      raise "Can't migrate with auto migrate enabled"
    else
      migrator = Pakyow::Data::Migrator.establish(
        adapter: args[:adapter],
        connection: args[:connection]
      )

      migrator.migrate!
      migrator.disconnect!
    end
  end

  desc "Finalize database migrations"
  task :finalize, [:adapter, :connection] do |_, args|
    migrator = Pakyow::Data::Migrator.establish(
      adapter: args[:adapter],
      connection: args[:connection],
      connection_overrides: {
        path: -> (path) {
          "#{path}-migrator"
        }
      }
    )

    # Create the migrator database unless it exists.
    #
    migrator.create!

    # Run the existing migrations on it.
    #
    migrator.migrate!

    # Create migrations for unmigrated schema.
    #
    migrator.finalize!

    # Cleanup.
    #
    migrator.disconnect!
    migrator.drop!
  end
end
