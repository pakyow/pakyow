# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Drop a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :drop, [:adapter, :connection] do |_, args|
    if connection = Pakyow.connection(args[:adapter], args[:connection])
      connection.disconnect
    end

    migrator = Pakyow::Data::Migrator.connect(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.drop!
    migrator.disconnect!
  end
end
