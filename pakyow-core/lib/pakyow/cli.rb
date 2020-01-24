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
    require "pakyow/cli/feedback"

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

    attr_reader :feedback

    def initialize(argv = ARGV, feedback: Feedback.new($stdout))
      argv = argv.dup

      @feedback = feedback

      command = parse_command(argv)
      options = parse_global_options!(argv)

      case command
      when "prototype"
        options[:env] = :prototype
      end

      if project_context?
        Pakyow.setup(env: options[:env])
      end

      load_commands

      if command
        task = find_task(command)

        if task.cli?
          options[:cli] = self
        end

        if task.app?
          setup_app_task(options)
        elsif options.key?(:app)
          @feedback.warn("app was ignored by command #{Support::CLI.style.blue(command)}")
        end

        if options[:help]
          @feedback.usage(task)
        else
          call_task(task, argv, options)
        end
      else
        @feedback.help(tasks)
      end
    rescue StandardError => error
      if @feedback.tty?
        @feedback.error(error)

        if task
          @feedback.usage(task, describe: false)
        else
          @feedback.help(tasks, header: false)
        end

        ::Process.exit(0)
      else
        raise error
      end
    end

    def tasks
      @tasks ||= Pakyow.tasks.select { |task|
        (task.global? && !project_context?) || (!task.global? && project_context?)
      }
    end

    def find_task(command)
      tasks.find { |task| task.name == command } || handle_unknown_command(command)
    end

    private def project_context?
      @project_context ||= File.exist?(Pakyow.config.environment_path + ".rb")
    end

    private def parse_command(argv)
      if argv.any? && !argv[0].start_with?("-")
        argv.shift
      else
        nil
      end
    end

    private def parse_global_options!(argv)
      options = {}

      parse_with_unknown_args!(argv) do
        OptionParser.new do |opts|
          opts.on("-eENV", "--env=ENV") do |e|
            options[:env] = e
          end

          opts.on("-aAPP", "--app=APP") do |a|
            options[:app] = a
          end

          opts.on("-h", "--help") do
            options[:help] = true
          end
        end
      end

      options[:env] ||= ENV["APP_ENV"] || ENV["RACK_ENV"] || "development"
      ENV["APP_ENV"] = ENV["RACK_ENV"] = options[:env]
      options
    end

    private def parse_with_unknown_args!(argv)
      parser, original, unparsed = yield, argv.dup, Array.new

      begin
        parser.order!(argv) do |arg|
          unparsed << arg
        end
      rescue OptionParser::InvalidOption => error
        unparsed.concat(error.args); retry
      end

      argv.replace((original & argv) + unparsed)
    end

    private def load_commands
      require "rake"

      load_tasks
    end

    private def load_tasks
      require "pakyow/task"
      Pakyow.tasks.clear
      Pakyow.config.tasks.paths.uniq.each_with_object(Pakyow.tasks) do |tasks_path, tasks|
        Dir.glob(File.join(File.expand_path(tasks_path), "**/*.rake")).each do |task_path|
          tasks.concat(Pakyow::Task::Loader.new(task_path).__tasks)
        end
      end
    end

    private def handle_unknown_command(command)
      if task = Pakyow.tasks.find { |task| task.name == command }
        if task.global?
          raise UnknownCommand.new_with_message(
            :not_in_global_context,
            command: command
          )
        else
          raise UnknownCommand.new_with_message(
            :not_in_project_context,
            command: command
          )
        end
      else
        raise UnknownCommand.new_with_message(
          command: command
        )
      end
    end

    private def setup_app_task(options)
      Pakyow.boot

      options[:app] = if options.key?(:app)
        Pakyow.app(options[:app]) || raise("`#{options[:app]}' is not a known app")
      elsif Pakyow.apps.count == 1
        Pakyow.apps.first
      elsif Pakyow.apps.count > 0
        raise "multiple apps were found; please specify one with the --app option"
      else
        raise "couldn't find an app to run this command for"
      end
    end

    private def call_task(task, argv, options)
      task.call(
        options.select { |key, _|
          (key == :app && task.app?) || key != :app
        }, argv.dup
      )
    rescue InvalidInput => error
      @feedback.error(error)
      @feedback.usage(task, describe: false)
    end
  end

  require "pakyow/behavior/tasks"
  include Behavior::Tasks
end
