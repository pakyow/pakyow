# frozen_string_literal: true

require "fileutils"
require "optparse"

require "pakyow/support/cli/style"

require "pakyow/error"

module Pakyow
  class CLI
    class InvalidInput < Error
    end

    GLOBAL_OPTIONS = {
      app: {
        description: "The app to run the command on",
        global: true
      },
      env: {
        description: "What environment to use",
        global: true
      }
    }

    def initialize(argv = ARGV)
      @argv = argv
      @options = {}
      @task = nil
      @command = nil

      parse_global_options
      configure_bootsnap
      load_environment
      load_tasks

      if @command
        setup_environment
        find_task_for_command
        set_app_for_command
        call_task
      else
        puts_help
      end
    rescue RuntimeError => error
      puts_error(error)

      if @task
        puts @task.help(describe: false)
      else
        puts_help(banner: false)
      end
    end

    private

    def current_path
      File.expand_path(".")
    end

    def environment_path
      File.join(current_path, "config/environment")
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

      @options[:env] ||= ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
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

    # rubocop:disable Lint/HandleExceptions
    def configure_bootsnap
      require "bootsnap"

      Bootsnap.setup(
        cache_dir:            File.join(current_path, "tmp/cache"),
        development_mode:     @options[:env] == "development",
        load_path_cache:      true,
        autoload_paths_cache: false,
        disable_trace:        false,
        compile_cache_iseq:   true,
        compile_cache_yaml:   true
      )
    rescue LoadError
    end
    # rubocop:enable Lint/HandleExceptions

    def load_environment
      require environment_path
    end

    def setup_environment
      Pakyow.setup(env: @options[:env])
    end

    def load_tasks
      Pakyow.load_tasks
    end

    def find_task_for_command
      unless @task = Pakyow.tasks.find { |task| task.name == @command }
        raise "#{Support::CLI.style.blue(@command)} is not a command"
      end
    end

    def set_app_for_command
      if @task.app?
        @options[:app] = if @options.key?(:app)
          Pakyow.find_app(@options[:app]) || raise("could not find app named #{Support::CLI.style.blue(@options[:app])}")
        elsif Pakyow.mounts.count == 1
          Pakyow.initialize_app_for_mount(Pakyow.mounts.values.first)
        elsif Pakyow.mounts.count > 0
          raise "found multiple apps; please specify one with the --app option"
        else
          raise "could not find any apps"
        end
      elsif @options.key?(:app)
        puts_warning "app was ignored by command #{Support::CLI.style.blue(@command)}"
      end
    end

    def call_task
      if @options[:help]
        puts @task.help
      else
        @task.call(@options, @argv.dup)
      end
    rescue InvalidInput => error
      puts_error(error)
      puts @task.help(describe: false)
    end

    def puts_error(error)
      puts "  #{Support::CLI.style.red("›")} #{error}"
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
      longest_name_length = Pakyow.tasks.map(&:name).max_by(&:length).length
      Pakyow.tasks.sort { |a, b| a.name <=> b.name }.each do |task|
        puts "  #{task.name}".ljust(longest_name_length + 4) + Support::CLI.style.yellow(task.description) + "\n"
      end
    end
  end
end
