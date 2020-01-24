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
        @output.puts command.help(describe: describe)
      end
    end
  end
end
