# frozen_string_literal: true

require "pakyow/support/cli/style"

require "pakyow/error"
require "pakyow/environment"

module Pakyow
  # The Pakyow command line interface.
  #
  # @api private
  class CLI
    require "pakyow/cli/feedback"
    require "pakyow/cli/parsers/command"
    require "pakyow/cli/parsers/global"

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

      parser = Parsers::Global.new(argv)
      command = parser.command
      options = parser.options

      case command
      when "prototype"
        options[:env] = :prototype
      end

      if project_context?
        Pakyow.setup(env: options[:env])
      end

      load_commands

      if command
        callable_command = find_callable_command(command)

        if callable_command.cli?
          options[:cli] = self
        end

        if callable_command.app?
          setup_options_for_app_command(options)
        elsif options.key?(:app)
          options.delete(:app)
          @feedback.warn("app was ignored by command #{Support::CLI.style.blue(command)}")
        end

        if options[:help]
          @feedback.usage(callable_command)
        else
          call_command(callable_command, argv, options)
        end
      else
        @feedback.help(commands)
      end
    rescue StandardError => error
      if @feedback.tty?
        @feedback.error(error)

        if callable_command
          @feedback.usage(callable_command, describe: false)
        else
          @feedback.help(commands, header: false)
        end

        ::Process.exit(0)
      else
        raise error
      end
    end

    def commands
      @commands ||= Pakyow.tasks.select { |task|
        (task.global? && !project_context?) || (!task.global? && project_context?)
      }
    end

    def find_callable_command(command)
      commands.find { |callable_command| callable_command.name == command } || handle_unknown_command(command)
    end

    private def project_context?
      @project_context ||= File.exist?(Pakyow.config.environment_path + ".rb")
    end

    private def load_commands
      require "rake"

      Pakyow.load_tasks
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

    private def setup_options_for_app_command(options)
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

    private def call_command(command, argv, options)
      parser = Parsers::Command.new(command, argv.dup)
      options = options.merge(parser.options)
      command.call({}, [], **options)
    rescue InvalidInput => error
      @feedback.error(error)
      @feedback.usage(command, describe: false)
    end
  end

  require "pakyow/behavior/tasks"
  include Behavior::Tasks
end
