# frozen_string_literal: true

require "fileutils"
require "optparse"

require "pakyow/support/cli/style"

require "pakyow/error"
require "pakyow/environment"

module Pakyow
  # The Pakyow command line interface.
  #
  # @api private
  class CLI
    class InvalidInput < Error; end

    GLOBAL_OPTIONS = {
      app: {
        description: "The app to run the command on",
        global: true
      }.freeze,
      env: {
        description: "What environment to use",
        global: true
      }.freeze
    }.freeze

    def initialize(argv = ARGV.dup)
      @argv = argv
      @options = {}
      @task = nil
      @command = nil

      parse_global_options

      if project_context?
        setup_environment
      end

      load_tasks

      if @command
        find_task_for_command
        set_app_for_command
        call_task
      else
        puts_help
      end
    rescue StandardError => error
      if $stdout.isatty
        puts_error(error)

        if @task
          puts @task.help(describe: false)
        else
          puts_help(banner: false)
        end

        ::Process.exit(0)
      else
        raise error
      end
    end

    private

    def tasks(filter_by_context = true)
      Pakyow.tasks.select { |task|
        !filter_by_context || (task.global? && !project_context?) || (!task.global? && project_context?)
      }
    end

    def project_context?
      File.exist?(Pakyow.config.environment_path + ".rb")
    end

    def parse_global_options
      parse_with_unknown_args do
        OptionParser.new do |opts|
          opts.on("-eENV", "--env=ENV") do |e|
            @options[:env] = e
          end

          opts.on("-aAPP", "--app=APP") do |a|
            @options[:app] = a
          end

          opts.on("-h", "--help") do
            @options[:help] = true
          end
        end
      end

      case @command
      when "prototype"
        @options.delete(:env)
      else
        @options[:env] ||= ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
      end

      ENV["APP_ENV"] = ENV["RACK_ENV"] = @options[:env]
    end

    def parse_with_unknown_args
      parser, unknown, original, unparsed = yield, Array.new, @argv.dup, Array.new

      begin
        parser.order!(@argv) do |arg|
          if @command
            unparsed << arg
          else
            @command = arg
          end
        end
      rescue OptionParser::InvalidOption => error
        unknown.concat(error.args); retry
      end

      @argv = (original & (@argv | unknown)) + unparsed
    end

    def setup_environment
      Pakyow.setup(env: environment_to_setup)
    end

    def environment_to_setup
      case @command
      when "prototype"
        :prototype
      else
        @options[:env]
      end
    end

    def load_tasks
      Pakyow.load_tasks
    end

    def find_task_for_command
      unless @task = tasks.find { |task| task.name == @command }
        if task = tasks(false).find { |task| task.name == @command }
          if task.global?
            raise UnknownCommand.new_with_message(
              :not_in_global_context,
              command: @command
            )
          else
            raise UnknownCommand.new_with_message(
              :not_in_project_context,
              command: @command
            )
          end
        else
          raise UnknownCommand.new_with_message(
            command: @command
          )
        end
      end
    end

    def set_app_for_command
      if @task.app?
        Pakyow.boot
        @options[:app] = if @options.key?(:app)
          Pakyow.app(@options[:app]) || raise("`#{@options[:app]}' is not a known app")
        elsif Pakyow.apps.count == 1
          Pakyow.apps.first
        elsif Pakyow.apps.count > 0
          raise "multiple apps were found; please specify one with the --app option"
        else
          raise "couldn't find an app to run this command for"
        end
      elsif @options.key?(:app)
        puts_warning "app was ignored by command #{Support::CLI.style.blue(@command)}"
      end
    end

    def call_task
      if @options[:help]
        puts @task.help
      else
        @task.call(@options.select { |key, _|
          (key == :app && @task.app?) || key != :app
        }, @argv.dup)
      end
    rescue InvalidInput => error
      puts_error(error)
      puts @task.help(describe: false)
    end

    def puts_error(error)
      puts "  #{Support::CLI.style.red("›")} #{Error::CLIFormatter.format(error.to_s)}"
    end

    def puts_warning(warning)
      puts "  #{Support::CLI.style.yellow("›")} #{warning}"
    end

    def puts_help(banner: true)
      if banner
        puts_banner
      end

      puts_usage
      puts_commands
    end

    def puts_banner
      puts Support::CLI.style.blue.bold("Pakyow Command Line Interface")
    end

    def puts_usage
      puts
      puts Support::CLI.style.bold("USAGE")
      puts "  $ pakyow [COMMAND]"
    end

    def puts_commands
      puts
      puts Support::CLI.style.bold("COMMANDS")
      longest_name_length = tasks.map(&:name).max_by(&:length).length
      tasks.sort { |a, b| a.name <=> b.name }.each do |task|
        puts "  #{task.name}".ljust(longest_name_length + 4) + Support::CLI.style.yellow(task.description) + "\n"
      end
    end
  end
end
