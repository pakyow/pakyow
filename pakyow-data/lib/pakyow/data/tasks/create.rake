# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Create a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :create, [:adapter, :connection] do |_, args|
    migrator = Pakyow::Data::Migrator.connect(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.create!
    migrator.disconnect!
  end
end
