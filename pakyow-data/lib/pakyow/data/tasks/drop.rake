# frozen_string_literal: true

require "pakyow/data/migrator"

namespace :db do
  desc "Drop a database"
  option :adapter, "The adapter to migrate"
  option :connection, "The connection to migrate"
  task :drop, [:adapter, :connection] do |_, args|
    begin
      if connection = Pakyow.connection(args[:adapter], args[:connection])
        connection.disconnect
      end
    # rubocop:disable Lint/HandleExceptions
    rescue ArgumentError
      # catch the case where the connection doesn't exist
    end
    # rubocop:enable Lint/HandleExceptions

    migrator = Pakyow::Data::Migrator.connect_global(
      adapter: args[:adapter],
      connection: args[:connection]
    )

    migrator.drop!
    migrator.disconnect!
  end
end
