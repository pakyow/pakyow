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
        global: true,
        short: "a"
      }.freeze,
      env: {
        description: "The environment to run this command under",
        global: true,
        short: "e"
      }.freeze
    }.freeze

    attr_reader :feedback

    class << self
      def run(argv = ARGV, output: $stdout)
        argv = argv.dup

        cli = new(feedback: Feedback.new(output))

        cli.handle do
          parser = Parsers::Global.new(argv)
          command = parser.command
          options = parser.options

          case command
          when "prototype"
            options[:env] = :prototype
          end

          Pakyow.load(env: options[:env])

          if command
            cli.with(command) do |callable_command|
              unless options[:help]
                parser = Parsers::Command.new(callable_command, argv)
                options = options.merge(parser.options)
              end

              Pakyow.boot if callable_command.boot?
              cli.call(command, **options)
            end
          else
            cli.help
          end
        end
      end

      # @api private
      def project_context?
        File.exist?(Pakyow.config.environment_path + ".rb")
      end
    end

    def initialize(feedback: Feedback.new($stdout))
      @feedback = feedback
    end

    def with(command)
      handle(find_callable_command(command)) do |callable_command|
        yield callable_command
      end
    end

    def handle(command = nil)
      yield command
    rescue StandardError => error
      if @feedback.tty?
        @feedback.error(error)

        if command
          @feedback.usage(command, describe: false)
        else
          @feedback.help(commands, header: false)
        end

        ::Process.exit(1)
      else
        raise error
      end
    end

    def call(command, **options)
      with(command) do |callable_command|
        # TODO: Once `Pakyow::Task` is removed, always pass `cli` as an option.
        #
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
          call_command(callable_command, options)
        end
      end
    end

    def help
      @feedback.help(commands)
    end

    def usage(command)
      case command
      when String, Symbol
        with(command) do |callable_command|
          @feedback.usage(callable_command)
        end
      else
        @feedback.usage(command)
      end
    end

    private def commands
      (Pakyow.commands.definitions + Pakyow.tasks).select { |command|
        (command.global? && !self.class.project_context?) || (!command.global? && self.class.project_context?)
      }
    end

    private def find_callable_command(command)
      command = command.to_s
      commands.find { |callable_command|
        callable_command.cli_name == command
      } || handle_unknown_command(command)
    end

    private def handle_unknown_command(command_name)
      if task = (Pakyow.commands.definitions + Pakyow.tasks).find { |command| command.cli_name == command_name }
        if task.global?
          raise UnknownCommand.new_with_message(
            :not_in_global_context,
            command: command_name
          )
        else
          raise UnknownCommand.new_with_message(
            :not_in_project_context,
            command: command_name
          )
        end
      else
        raise UnknownCommand.new_with_message(
          command: command_name
        )
      end
    end

    private def setup_options_for_app_command(options)
      options[:app] = if options.key?(:app)
        case options[:app]
        when Application
          options[:app]
        else
          Pakyow.app(options[:app]) || raise("`#{options[:app]}' is not a known app")
        end
      elsif Pakyow.apps.count == 1
        Pakyow.apps.first
      elsif Pakyow.apps.count > 0
        raise "multiple apps were found; please specify one with the --app option"
      else
        raise "couldn't find an app to run this command for"
      end
    end

    private def call_command(command, options)
      if command.is_a?(Pakyow::Task)
        command.call({}, [], **options)
      else
        command.call(**options)
      end
    end

    class << self
      UNAVAILABLE_SHORT_NAMES = %i(a e h).freeze

      # @api private
      def shortable?(short_name)
        !UNAVAILABLE_SHORT_NAMES.include?(short_name.to_sym)
      end
    end
  end
end
