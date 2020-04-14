# frozen_string_literal: true

require "rake"
require "forwardable"
require "optparse"

require "pakyow/support/cli/style"
require "pakyow/support/deep_freeze"
require "pakyow/support/deprecatable"

require_relative "cli"

module Pakyow
  # Base task class that extends rake with additional functionality.
  #
  class Task
    extend Support::Deprecatable
    deprecate solution: "use `Pakyow::Command'"

    include Rake::DSL

    extend Forwardable
    def_delegators :@rake, :name
    alias cli_name name

    attr_reader :description, :arguments, :options, :flags, :short_names

    def initialize(namespace: [], description: nil, arguments: {}, options: {}, flags: {}, task_args: [], global: false, &block)
      @description, @arguments, @options, @flags, @global = description, arguments, options, flags, global
      @short_names = determine_short_names

      if namespace.any?
        send(:namespace, namespace.join(":")) do
          define_task(task_args, block)
        end
      else
        define_task(task_args, block)
      end
    end

    def call(legacy_options = {}, legacy_argv = [], **options)
      legacy_options = legacy_options.merge(options)
      parse_options(legacy_argv, legacy_options)
      parse_arguments(legacy_argv, legacy_options)

      final_options = legacy_options

      check_options(final_options)
      @rake.invoke(*args.map { |arg| final_options[arg] })
    end

    def app?
      args.include?(:app)
    end

    def cli?
      args.include?(:cli)
    end

    def global?
      @global == true
    end

    def boot?
      false
    end

    def help(describe: true)
      string = StringIO.new
      feedback = CLI::Feedback.new(string)
      feedback.usage(self, describe: describe)
      string.rewind
      string.read
    end

    def flag?(key)
      @flags.include?(key.to_sym)
    end

    private

    def sorted_arguments
      @arguments.sort_by { |key, _| args.index(key) }
    end

    def sorted_options
      @options.sort
    end

    def sorted_options_and_flags
      @options.merge(@flags).sort
    end

    def define_task(task_args, task_block)
      @rake = task(*task_args) { |task, args|
        instance_exec(task, args, &task_block)
      }
    end

    def args
      @args ||= @rake.arg_names.map(&:to_sym)
    end

    def parse_options(argv, options)
      unparsed = Array.new
      OptionParser.new { |opts|
        @flags.keys.each do |flag|
          opts.on("--#{flag}") do |v|
            options[flag] = v
          end
        end

        @options.keys.each do |option|
          match = ["--#{option}=VAL"]
          if @short_names.key?(option)
            match.unshift("-#{@short_names[option]}VAL")
          end

          opts.on(*match) do |v|
            options[option] = v
          end
        end
      }.order!(argv) do |arg|
        unparsed << arg
      end

      argv.concat(unparsed)
    rescue OptionParser::InvalidOption => error
      raise CLI::InvalidInput, "`#{error.args.first}' is not a supported option"
    end

    def parse_arguments(argv, options)
      sorted_arguments.each do |key, argument|
        if argv.any?
          options[key] = argv.shift
        elsif argument[:required] && !options.include?(key)
          raise CLI::InvalidInput, "`#{key}' is a required argument"
        end
      end

      if argv.any?
        raise CLI::InvalidInput, "`#{argv.shift}' is not a supported argument"
      end
    end

    def check_options(options)
      @options.each do |key, option|
        if option[:required] && !options.key?(key)
          raise CLI::InvalidInput, "`#{key}' is a required option"
        end
      end

      options.keys.each do |key|
        unless global_options.key?(key) || args.include?(key)
          raise CLI::InvalidInput, "`#{key}' is not a supported option"
        end
      end
    end

    def global_options
      Hash[@options.select { |_, option|
        option[:global]
      }]
    end

    UNAVAILABLE_SHORT_NAMES = %w(a e h).freeze
    def determine_short_names
      short_names = {
        env: "e"
      }

      @options.each do |name, opts|
        if short = opts[:short]
          short = name[0] if short == :default
          unless short_names.value?(short) || UNAVAILABLE_SHORT_NAMES.include?(short)
            short_names[name] = short
          end
        end
      end

      @flags.each do |name, opts|
        if short = opts[:short]
          unless short_names.value?(short) || UNAVAILABLE_SHORT_NAMES.include?(short)
            short_names[name] = short
          end
        end
      end

      short_names
    end

    class Loader
      attr_reader :__namespace, :__description, :__arguments, :__options, :__flags, :__tasks, :__global

      def initialize(path)
        @__namespace = []
        @__description = nil
        @__arguments = {}
        @__options = {}
        @__flags = {}
        @__tasks = []
        @__global = false

        eval(File.read(path), binding, path)
      end

      def namespace(name, &block)
        @__namespace << name.to_sym
        instance_exec(&block)
        @__namespace.pop
      end

      def describe(description)
        @__description = description
      end
      alias :desc :describe

      def argument(name, description, required: false)
        @__arguments[name.to_sym] = {
          description: description,
          required: required
        }
      end

      def option(name, description, required: false, short: name[0])
        @__options[name.to_sym] = {
          description: description,
          required: required,
          short: short
        }
      end

      def flag(name, description, short: nil)
        @__flags[name.to_sym] = {
          description: description,
          short: short
        }
      end

      def task(*args, &block)
        @__tasks << Task.new(
          namespace: @__namespace,
          description: @__description,
          arguments: @__arguments,
          options: CLI::GLOBAL_OPTIONS.select { |key, _|
            key == :env || args[1].to_a.include?(key)
          }.reject { |key, _|
            key == :env && args[0] == :prototype
          }.merge(@__options),
          flags: @__flags,
          task_args: args,
          global: @__global,
          &block
        )

        @__description = nil
        @__arguments = {}
        @__options = {}
        @__global = false
      end

      def global_task(*args, &block)
        @__global = true
        task(*args, &block)
      end
    end
  end
end
