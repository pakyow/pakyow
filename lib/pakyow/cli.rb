# frozen_string_literal: true

require "thor"

module Pakyow
  # @api private
  class CLI < Thor
    def self.known_command?(command)
      !find_command_possibilities(command).empty?
    end

    map ["--version", "-v"] => :version

    desc "new PROJECT_PATH", "Create a new Pakyow project"
    long_desc <<-DESC
      The `pakyow new` command creates a new Pakyow project at the path you specify.

      $ pakyow new path/to/project
    DESC

    def new(name = nil)
      require "generators/pakyow/app/app_generator"
      Generators::AppGenerator.start([name])
      puts "Done! Run `cd #{name}; bundle exec pakyow server` to get started!"
    end

    desc "console [ENVIRONMENT]", "Start an interactive Pakyow console"
    long_desc <<-DESC
      The `pakyow console` command starts a console session for the current Pakyow project,
      providing access to an application instance that you can interact with.

      If environment is unspecified, the default environment (#{Pakyow.config.env.default}) will be used.
    DESC

    def console(env = nil)
      require "pakyow/commands/console"
      Commands::Console.new(env: env).run
    rescue LoadError => e
      raise Thor::Error, "Error: #{e.message}\n" \
        "You must run the `pakyow console` command in the root directory of a Pakyow project."
    end

    desc "server [ENVIRONMENT] [options]", "Start a Pakyow application"
    long_desc <<-DESC
      The `pakyow server` command starts the server for the current Pakyow project.

      If environment is unspecified, the default environment (#{Pakyow.config.env.default}) will be used.
    DESC
    option :port, type: :string, aliases: :"-p"
    option :host, type: :string, aliases: :"-h"
    option :server, type: :string, aliases: :"-s"
    option :standalone, type: :boolean, default: false

    def server(env = nil)
      require "pakyow/commands/server"
      Commands::Server.new(
        env: env,
        port: options[:port],
        host: options[:host],
        server: options[:server],
        standalone: options[:standalone]
      ).run
    rescue LoadError => e
      raise Thor::Error, "Error: #{e.message}\n" \
        "You must run the `pakyow server` command in the root directory of a Pakyow project."
    end

    desc "version", "Display the installed Pakyow version"
    def version
      puts "Pakyow v#{VERSION}"
    end

    desc "exec", "Run a task for the environment or an app"
    option :app, type: :string, aliases: :"-a"
    option :args, type: :array, default: []
    option :env, type: :string
    def exec(task)
      require "pakyow/commands/exec"
      Commands::ExecTask.new(
        task,
        app: options[:app],
        args: options[:args],
        env: options[:env]
      ).run
    end
  end
end
