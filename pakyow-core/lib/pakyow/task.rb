# frozen_string_literal: true

require "rake"
require "forwardable"
require "optparse"

require "pakyow/support/deep_freeze"
require "pakyow/support/cli/style"

require "pakyow/cli"

module Pakyow
  # Base task class that extends rake with additional functionality.
  #
  class Task
    include Rake::DSL

    extend Forwardable
    def_delegators :@rake, :name

    extend Support::DeepFreeze
    insulate :rake

    attr_reader :description

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

        longest_length = (@options.keys + @flags.keys).map(&:to_s).max_by(&:length).length
        sorted_options_and_flags.each do |key, option|
          description = Support::CLI.style.yellow(option[:description])

          if option[:required]
            description += Support::CLI.style.red(" (required)")
          end

          prefix = if @flags.key?(key)
            "      --#{key}"
          else
            if @short_names.key?(key)
              "  -#{key.to_s[0]}, --#{key}=#{key}"
            else
              "      --#{key}=#{key}"
            end
          end

          text += prefix.ljust(longest_length * 2 + 11) + description + "\n"
        end
      end

      text
    end

    def app?
      args.include?(:app)
    end

    def global?
      @global == true
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
        elsif argument[:required]
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

      def option(name, description, required: false, short: :default)
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
