module DatabaseHelpers
  require "pakyow/data"
  require "pakyow/data/connection"
  require "pakyow/data/migrator"
  require "pakyow/data/adapters/sql"

  def wait_for_sql_database!(options)
    options = sql_options(options)

    iterations = 0
    until iterations > 30
      connection = Pakyow::Data::Connection.new(opts: options, type: :sql, name: :test)

      if connection.connected?
        break
      else
        iterations += 1
        sleep 1
      end
    end

    if connection.connected?
      connection.disconnect
    else
      raise RuntimeError, "Could not connect to database: #{options}"
    end
  end

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
end
