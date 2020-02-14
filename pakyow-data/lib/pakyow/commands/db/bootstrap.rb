# frozen_string_literal: true

command :db, :bootstrap, boot: false do
  describe "Bootstrap a database"

  option :adapter, "The database adapter", default: -> { Pakyow.config.data.default_adapter }
  option :connection, "The database connection", default: -> { Pakyow.config.data.default_connection }

  required :cli

  action do
    %w(db:create db:migrate).each do |command|
      @cli.call(command, adapter: @adapter, connection: @connection)
    end
  end
end
