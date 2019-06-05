# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Create a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :create, [:adapter, :connection] do |_, args|
    unless Pakyow.booted?
      Pakyow.boot(unsafe: true)
    end

    migrator = Pakyow::Data::Migrator.connect_global(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.create!
    migrator.disconnect!
  end
end
