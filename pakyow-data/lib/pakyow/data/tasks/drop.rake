# frozen_string_literal: true

require "pakyow/data/migrator"
require "pakyow/data/migrators/mysql"
require "pakyow/data/migrators/postgres"
require "pakyow/data/migrators/sqlite"

namespace :db do
  desc "Drop a database"
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
end
