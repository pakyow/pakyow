# frozen_string_literal: true

command :db, :reset, boot: false do
  describe "Reset a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  required :cli

  action do
    %w(db:drop db:bootstrap).each do |command|
      @cli.call(command, adapter: @adapter, connection: @connection)
    end
  end
end
