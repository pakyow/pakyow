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

  require "pakyow/data/connection"
  require "pakyow/data/migrator"
  require "pakyow/data/adapters/sql"

  # FIXME: We do this because we setup a migrator (which might use the logger) ahead of the logger
  # being initialized. The correct fix would be to always have a default logger, then replace it
  # when booting the environment.
  #
  def install_temporary_logger
    installed = false
    if Pakyow.logger.nil?
      Pakyow.instance_variable_set(:@logger, Logger.new(IO::NULL))
      installed = true
    end

    ret = yield

    if installed
      Pakyow.remove_instance_variable(:@logger)
    end

    ret
  end

  def create_sql_database(options)
    migrator = Pakyow::Data::Migrator.connect_raw(opts: sql_options(options), type: :sql, name: :default)

    install_temporary_logger do
      migrator.create!
    end
  ensure
    migrator.disconnect!
  end

  def drop_sql_database(options)
    migrator = Pakyow::Data::Migrator.connect_raw(opts: sql_options(options), type: :sql, name: :default)

    install_temporary_logger do
      migrator.drop!
    end
  ensure
    migrator.disconnect!
  end

  def sql_database_exists?(options)
    options = sql_options(options)

    if options[:adapter] == "sqlite"
      File.exist?(options[:path])
    else
      connection = Pakyow::Data::Connection.new(opts: options, type: :sql, name: :exist)

      result = case connection.opts[:adapter]
      when "postgres"
        connection.adapter.connection.fetch("select exists(SELECT datname FROM pg_catalog.pg_database WHERE lower(datname) = lower('#{connection.opts[:initial][:path]}'))").first[:exists]
      when "mysql2"
        !connection.adapter.connection.fetch("SHOW DATABASES LIKE '#{connection.opts[:initial][:path]}'").first.nil?
      end

      connection.disconnect

      result
    end
  end

  def sql_options(options)
    options = Pakyow::Data::Connection.parse_connection_string(options) if options.is_a?(String)
    options[:initial] = Pakyow::Data::Adapters::Sql.build_opts(path: options[:path])

    case options[:adapter]
    when "postgres"
      options[:path] = "template1"
    when "mysql2"
      options[:path] = nil
    end

    options
  end

  def database_urls
    @database_urls ||= [
      ENV["DATABASE_URL__POSTGRES"],
      ENV["DATABASE_URL__POSTGRES_2"],
      ENV["DATABASE_URL__POSTGRES_3"],
      ENV["DATABASE_URL__MYSQL"]
    ].freeze
  end

  config.before :suite do
    database_urls.each do |database_url|
      # This can hang indefinitely from time to time, so wrap in a timeout.
      #
      Timeout::timeout(15) do
        drop_sql_database(database_url)
      end

      create_sql_database(database_url)
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

ENV["MYSQL_URL"] ||= "mysql2://localhost"
ENV["POSTGRES_URL"] ||= "postgres://localhost"
ENV["DATABASE_URL__MYSQL"] ||= File.join(ENV["MYSQL_URL"], "pakyow-test")
ENV["DATABASE_URL__POSTGRES"] ||= File.join(ENV["POSTGRES_URL"], "pakyow-test")
ENV["DATABASE_URL__POSTGRES_2"] ||= File.join(ENV["POSTGRES_URL"], "pakyow-test-two")
ENV["DATABASE_URL__POSTGRES_3"] ||= File.join(ENV["POSTGRES_URL"], "pakyow-test-three")
