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

    def initialize(argv = ARGV.dup, feedback: Feedback.new($stdout))
      @argv = argv
      @options = {}
      @task = nil
      @command = nil
      @feedback = feedback

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
        @feedback.help(tasks)
      end
    rescue StandardError => error
      if @feedback.tty?
        @feedback.error(error)

        if @task
          @feedback.usage(@task, describe: false)
        else
          @feedback.help(tasks, header: false)
        end

        ::Process.exit(0)
      else
        raise error
      end
    end

    private

    def tasks(filter_by_context = true)
      Pakyow.legacy_tasks.select { |task|
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
      parser, original, unparsed = yield, @argv.dup, Array.new

      begin
        parser.order!(@argv) do |arg|
          if @command
            unparsed << arg
          else
            @command = arg
          end
        end
      rescue OptionParser::InvalidOption => error
        unparsed.concat(error.args); retry
      end

      @argv = (original & @argv) + unparsed
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
      require "rake"

      load_legacy_tasks
    end

    def load_legacy_tasks
      require "pakyow/task"
      Pakyow.legacy_tasks.clear
      Pakyow.config.tasks.paths.uniq.each_with_object(Pakyow.legacy_tasks) do |tasks_path, tasks|
        Dir.glob(File.join(File.expand_path(tasks_path), "**/*.rake")).each do |task_path|
          tasks.concat(Pakyow::Task::Loader.new(task_path).__tasks)
        end
      end
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
        @feedback.warn("app was ignored by command #{Support::CLI.style.blue(@command)}")
      end
    end

    def call_task
      if @options[:help]
        @feedback.usage(@task)
      else
        @task.call(@options.select { |key, _|
          (key == :app && @task.app?) || key != :app
        }, @argv.dup)
      end
    rescue InvalidInput => error
      @feedback.error(error)
      @feedback.usage(@task, describe: false)
    end
  end

  require "pakyow/behavior/tasks"
  include Behavior::Tasks
end
