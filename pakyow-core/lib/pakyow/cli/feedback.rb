# frozen_string_literal: true

require "forwardable"

require "pakyow/support/cli/style"

require "pakyow/error"

module Pakyow
  class CLI
    # Provides feedback to the command line user.
    #
    # @api private
    class Feedback
      extend Forwardable
      def_delegators :@output, :tty?

      def initialize(output = $stdout)
        @output = output
      end

      def error(error)
        @output.puts "  #{Support::CLI.style.red("›")} #{Error::CLIFormatter.format(error.to_s)}"
      end

      def warn(warning)
        @output.puts "  #{Support::CLI.style.yellow("›")} #{warning}"
      end

      def help(commands, header: true)
        if header
          @output.puts Support::CLI.style.blue.bold("Pakyow Command Line Interface")
        end

        @output.puts
        @output.puts Support::CLI.style.bold("USAGE")
        @output.puts "  $ pakyow [COMMAND]"

        @output.puts
        @output.puts Support::CLI.style.bold("COMMANDS")
        longest_name_length = commands.map(&:name).max_by(&:length).length
        commands.sort { |a, b| a.name <=> b.name }.each do |command|
          @output.puts "  #{command.name}".ljust(longest_name_length + 4) + Support::CLI.style.yellow(command.description) + "\n"
        end
      end

      def usage(command, describe: true)
        required_arguments = command.send(:sorted_arguments).select { |_, argument|
          argument[:required]
        }.map { |key, _|
          "[#{key.to_s.upcase}]"
        }.join(" ")

        required_options = command.send(:sorted_options).select { |_, option|
          option[:required]
        }.map { |key, _|
          "--#{key}=#{key}"
        }.join(" ")

        # text = String.new

        if describe
          @output.puts Support::CLI.style.blue.bold(command.description)
        end

        @output.puts <<~HELP

          #{Support::CLI.style.bold("USAGE")}
            $ pakyow #{[command.name, required_arguments, required_options].reject(&:empty?).join(" ")}
        HELP

        if command.arguments.any?
          @output.puts <<~HELP

            #{Support::CLI.style.bold("ARGUMENTS")}
          HELP

          longest_length = command.arguments.keys.map(&:to_s).max_by(&:length).length
          command.send(:sorted_arguments).each do |key, argument|
            description = Support::CLI.style.yellow(argument[:description])
            description += Support::CLI.style.red(" (required)") if argument[:required]
            @output.puts "  #{key.upcase}".ljust(longest_length + 4) + description
          end
        end

        if command.options.any?
          @output.puts <<~HELP

            #{Support::CLI.style.bold("OPTIONS")}
          HELP

          longest_length = (command.options.keys + command.flags.keys).map(&:to_s).max_by(&:length).length
          command.send(:sorted_options_and_flags).each do |key, option|
            description = Support::CLI.style.yellow(option[:description])

            if option[:required]
              description += Support::CLI.style.red(" (required)")
            end

            prefix = if command.flags.key?(key)
              "      --#{key}"
            else
              if command.short_names.key?(key)
                "  -#{key.to_s[0]}, --#{key}=#{key}"
              else
                "      --#{key}=#{key}"
              end
            end

            @output.puts prefix.ljust(longest_length * 2 + 11) + description
          end
        end
      end
    end
  end
end
