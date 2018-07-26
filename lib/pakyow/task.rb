# frozen_string_literal: true

require "rake"
require "forwardable"
require "optparse"

require "pakyow/support/cli/style"

require "pakyow/cli"

module Pakyow
  # @api private
  class Task
    include Rake::DSL

    extend Forwardable
    def_delegators :@rake, :name, :reenable

    attr_reader :description

    def initialize(namespace: [], description: nil, arguments: {}, options: {}, task_args: [], &block)
      @description, @arguments, @options = description, arguments, options

      if namespace.any?
        send(:namespace, namespace.join(":")) do
          define_task(task_args, block)
        end
      else
        define_task(task_args, block)
      end
    end

    def call(options = {}, argv = [])
      parse_options(argv, options)
      parse_arguments(argv, options)
      check_options(options)

      @rake.invoke(*args.map { |arg|
        options[arg]
      })
    end

    def help(describe: true)
      required_arguments = sorted_arguments.select { |_, argument|
        argument[:required]
      }.map { |key, _|
        "[#{key.to_s.upcase}]"
      }.join(" ")

      required_options = sorted_options.select { |_, option|
        option[:required]
      }.map { |key, _|
        "--#{key}=#{key}"
      }.join(" ")

      text = String.new

      if describe
        text << Support::CLI.style.blue.bold(@description) + "\n"
      end

      text += <<~HELP

        #{Support::CLI.style.bold("USAGE")}
          $ pakyow #{[name, required_arguments, required_options].reject(&:empty?).join(" ")}
      HELP

      if @arguments.any?
        text += <<~HELP

          #{Support::CLI.style.bold("ARGUMENTS")}
        HELP

        longest_length = @arguments.keys.map(&:to_s).max_by(&:length).length
        sorted_arguments.each do |key, argument|
          description = Support::CLI.style.yellow(argument[:description])
          if argument[:required]
            description += Support::CLI.style.red(" (required)")
          end
          text += "  #{key.upcase}".ljust(longest_length + 4) + description + "\n"
        end
      end

      if @options.any?
        text += <<~HELP

          #{Support::CLI.style.bold("OPTIONS")}
        HELP

        longest_length = @options.keys.map(&:to_s).max_by(&:length).length
        sorted_options.each do |key, option|
          description = Support::CLI.style.yellow(option[:description])
          if option[:required]
            description += Support::CLI.style.red(" (required)")
          end
          text += "  -#{key.to_s[0]}, --#{key}=#{key}".ljust(longest_length * 2 + 11) + description + "\n"
        end
      end

      text
    end

    def app?
      args.include?(:app)
    end

    private

    def sorted_arguments
      @arguments.sort_by { |key, _| args.index(key) }
    end

    def sorted_options
      @options.sort
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
        @options.keys.each do |option|
          opts.on("-#{option.to_s[0]}VAL", "--#{option}=VAL") do |v|
            options[option] = v
          end
        end
      }.order!(argv) do |arg|
        unparsed << arg
      end

      argv.concat(unparsed)
    rescue OptionParser::InvalidOption => error
      raise CLI::InvalidInput, "Unexpected option: #{error.args.first}"
    end

    def parse_arguments(argv, options)
      sorted_arguments.each do |key, argument|
        if argv.any?
          options[key] = argv.shift
        elsif argument[:required]
          raise CLI::InvalidInput, "Missing required argument: #{key}"
        end
      end

      if argv.any?
        raise CLI::InvalidInput, "Unexpected argument: #{argv.shift}"
      end
    end

    def check_options(options)
      @options.each do |key, option|
        if option[:required] && !options.key?(key)
          raise CLI::InvalidInput, "Missing required option: #{key}"
        end
      end

      options.keys.each do |key|
        unless global_options.key?(key) || args.include?(key)
          raise CLI::InvalidInput, "Unexpected option: #{key}"
        end
      end
    end

    def global_options
      Hash[@options.select { |_, option|
        option[:global]
      }]
    end

    class Loader
      attr_reader :__namespace, :__description, :__arguments, :__options, :__tasks

      def initialize(path)
        @__namespace = []
        @__description = nil
        @__arguments = {}
        @__options = {}
        @__tasks = []

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

      def option(name, description, required: false)
        @__options[name.to_sym] = {
          description: description,
          required: required
        }
      end

      def task(*args, &block)
        @__tasks << Task.new(
          namespace: @__namespace,
          description: @__description,
          arguments: @__arguments,
          options: CLI::GLOBAL_OPTIONS.merge(@__options),
          task_args: args,
          &block
        )

        @__description = nil
        @__arguments = {}
        @__options = {}
      end
    end
  end
end
