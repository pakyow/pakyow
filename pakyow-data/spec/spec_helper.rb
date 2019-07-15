start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/data"

require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  if ENV.key?("CI")
    if ENV.key?("CI_DB")
      config.filter_run ENV["CI_DB"].to_sym => true
    else
      config.filter_run_excluding mysql: true
      config.filter_run_excluding sqlite: true
      config.filter_run_excluding postgres: true
    end
  end

  config.before do
    allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:post) do |_, *args, &block|
      block.call(*args)
    end
  end

  config.after do
    connections = Pakyow.data_connections[:sql].to_h.values.select { |connection|
      connection.connected?
    }

    if connections.empty? && @data_connection
      connections << @data_connection
    end

    connections.each do |connection|
      begin
        connection.adapter.connection.tables.each do |table|
          case connection.opts[:adapter]
          when "sqlite"
            connection.adapter.connection.run "PRAGMA foreign_keys = off"
            connection.adapter.connection.run "DROP TABLE #{table}"
          when "mysql2"
            connection.adapter.connection.run "SET FOREIGN_KEY_CHECKS = 0"
            connection.adapter.connection.run "DROP TABLE #{table}"
          else
            connection.adapter.connection.run "DROP TABLE #{table} CASCADE"
          end
        end
      rescue Sequel::DatabaseDisconnectError, Sequel::DatabaseError
        # catch errors caused by closed connections
      end
    end

    Pakyow.data_connections.values.flat_map(&:values).each(&:disconnect)
    @data_connection.disconnect if @data_connection
  end

  def connection_name
    :default
  end

  def connection_type
    :sql
  end

  def data
    Pakyow.apps.first.data
  end

  def data_connection
    unless data_connection = Pakyow.data_connections.dig(connection_type, connection_name)
      @data_connection&.disconnect
      data_connection = Pakyow::Data::Connection.new(type: connection_type, name: :migrator, string: connection_string)
      @data_connection = data_connection
    end

    data_connection
  end

  def raw_connection
    data_connection.adapter.connection
  end

  def schema(table)
    # For some reason the reload option doesn't discover new tables.
    #
    raw_connection.tables

    raw_connection.schema(table, reload: true)
  end

  def setup(*)
    # Disconnect any existing data connections. Prevents issues when setup is called more than once.
    #
    Pakyow.data_connections.values.flat_map(&:values).each(&:disconnect)

    # Reset the apps list, so we're always working with a predictable set.
    #
    Pakyow.instance_variable_set(:@apps, [])
  end
end

require_relative "../../spec/context/cli_context"
require_relative "../../spec/context/app_context"
require_relative "./context/migration_context"
