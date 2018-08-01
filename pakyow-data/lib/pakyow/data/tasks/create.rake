# frozen_string_literal: true

require "pakyow/data/migrator"
require "pakyow/data/migrators/mysql"
require "pakyow/data/migrators/postgres"
require "pakyow/data/migrators/sqlite"

namespace :db do
  desc "Create a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :create, [:adapter, :connection] do |_, args|
    migrator = Pakyow::Data::Migrator.establish(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.create!
    migrator.disconnect!
  end
end
