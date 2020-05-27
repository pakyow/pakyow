# frozen_string_literal: true

require "forwardable"

require "pakyow/support/cli/style"

require_relative "../error"

module Pakyow
  class CLI
    # Provides feedback to the command line user.
    #
    # @api private
    class Feedback
      extend Forwardable
      def_delegators :@output, :tty?, :puts

      def initialize(output = $stdout)
        @output = output
      end

      def error(error)
        puts "  #{Support::CLI.style.red("›")} #{Error::CLIFormatter.format(error.to_s)}"
      end

      def backtrace(error)
        unless error.is_a?(Error)
          error = Error.build(error)
        end

        puts
        Error::CLIFormatter.new(error).to_s.each_line do |line|
          puts "    #{line}"
        end
      end

      def warn(warning)
        puts "  #{Support::CLI.style.yellow("›")} #{warning}"
      end

      def help(commands, header: true)
        commands = commands.select(&:description)

        if header
          puts Support::CLI.style.blue.bold("Pakyow Command Line Interface")
        end

        puts
        puts Support::CLI.style.bold("USAGE")
        puts "  $ pakyow [COMMAND]"

        if commands.any?
          puts
          puts Support::CLI.style.bold("COMMANDS")
          longest_name_length = commands.map(&:cli_name).max_by(&:length).length
          commands.sort { |a, b| a.cli_name <=> b.cli_name }.each do |command|
            puts "  #{command.cli_name}".ljust(longest_name_length + 4) + Support::CLI.style.yellow(command.description) + "\n"
          end
        end
      end

      def usage(command, describe: true)
        required_arguments = command.arguments.select { |_, argument|
          argument[:required]
        }.map { |key, _|
          "[#{key.to_s.upcase}]"
        }.join(" ")

        required_options = command.options.select { |_, option|
          option[:required]
        }.map { |key, _|
          "--#{key}=#{key}"
        }.join(" ")

        if describe
          puts Support::CLI.style.blue.bold(command.description)
        end

        puts <<~HELP

          #{Support::CLI.style.bold("USAGE")}
            $ pakyow #{[command.cli_name, required_arguments, required_options].reject(&:empty?).join(" ")}
        HELP

        if command.arguments.any?
          puts <<~HELP

            #{Support::CLI.style.bold("ARGUMENTS")}
          HELP

          longest_length = command.arguments.keys.map(&:to_s).max_by(&:length).length
          command.arguments.each_pair do |key, argument|
            next if argument[:description].nil? || argument[:description].empty?

            description = Support::CLI.style.yellow(argument[:description])
            description += Support::CLI.style.red(" (required)") if argument[:required]
            puts "  #{key.upcase}".ljust(longest_length + 4) + description
          end
        end

        options = {}
        options[:app] = CLI::GLOBAL_OPTIONS[:app] if command.app?
        options[:env] = CLI::GLOBAL_OPTIONS[:env]
        options = options.merge(command.options).merge(command.flags)

        if options.any?
          puts <<~HELP

            #{Support::CLI.style.bold("OPTIONS")}
          HELP

          longest_length = options.keys.map(&:to_s).max_by(&:length).length
          options.each_pair do |key, option|
            next if option[:description].nil? || option[:description].empty?

            description = option[:description]

            if !command.flag?(key) && default = option[:default]
              default_value = case default
              when Proc
                default.call
              else
                default
              end

              description += " (default: #{default_value})"
            end

            description = Support::CLI.style.yellow(description)

            if option[:required]
              description += Support::CLI.style.red(" (required)")
            end

            prefix = if command.flag?(key)
              "      --#{key}"
            else
              if short = option[:short]
                "  -#{short}, --#{key}=#{key}"
              else
                "      --#{key}=#{key}"
              end
            end

            puts prefix.ljust(longest_length * 2 + 11) + description
          end
        end
      end
    end
  end
end
