require "thor"

module Pakyow
  class CommandLineInterface < Thor
    map ["--version", "-v"] => :version

    desc "new DESTINATION", <<DESC
Description:
    The 'pakyow new' command creates a new Pakyow application at the path
    specified.

Example:
    pakyow new path/to/application

    This generates a new Pakyow application in path/to/application.
DESC
    def new(destination)
      require "generators/pakyow/app/app_generator"
      Pakyow::Generators::AppGenerator.start(destination)
    end

    desc "console ENVIRONMENT", <<DESC
Description:
    The 'pakyow console' command stages the application and starts an interactive
    session. If environment is not specified, the default_environment defined by
    your application will be used.

Example:
    pakyow console development

    This starts the console with the 'development' configuration.
DESC
    def console(environment = :development)
      require "pakyow/commands/console"
      Pakyow::Commands::Console
        .new(environment: environment)
        .run
    end

    desc "server ENVIRONMENT", <<DESC
Description:
    The 'pakyow server' command starts the application server.

    If environment is not specified, the default_environment defined
    by your application will be used.

    If port is not specified, the port defined
    by your application will be used (defaults to 3000).

Example:
    pakyow server development -p 3001

    This starts the application server on port 3001 with the 'development' configuration.
DESC
    option :port, type: :numeric, aliases: :p, default: 3000
    def server(environment = :development)
      require "pakyow/commands/server"
      Pakyow::Commands::Server
        .new(environment: environment, port: options[:port])
        .run
    end

    desc "version", "Display the installed Pakyow version"
    def version
      puts "Pakyow #{Pakyow::VERSION}"
    end
  end
end
