start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/data"

require_relative "../../spec/helpers/app_helpers"
require_relative "../../spec/helpers/mock_handler"

RSpec.configure do |config|
  config.include AppHelpers

  if ENV.key?("CI")
    if ENV.key?("CI_DB")
      config.filter_run ENV["CI_DB"].to_sym => true
    else
      config.filter_run_excluding mysql: true
      config.filter_run_excluding sqlite: true
      config.filter_run_excluding postgres: true
    end
  end

  config.after do
    Pakyow.data_connections[:sql].to_h.values.reject { |connection|
      connection.adapter.connection.nil?
    }.each do |connection|
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
    end

    Pakyow.data_connections.values.flat_map(&:values).each(&:disconnect)
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

  def connection
    Pakyow.data_connections[connection_type][connection_name]
  end

  def raw_connection
    connection.adapter.connection
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
require_relative "../../spec/context/testable_app_context"
require_relative "./context/migration_context"

$data_app_boilerplate = Proc.new do
end
