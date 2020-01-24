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

      def help(tasks, header: true)
        if header
          @output.puts Support::CLI.style.blue.bold("Pakyow Command Line Interface")
        end

        @output.puts
        @output.puts Support::CLI.style.bold("USAGE")
        @output.puts "  $ pakyow [COMMAND]"

        @output.puts
        @output.puts Support::CLI.style.bold("COMMANDS")
        longest_name_length = tasks.map(&:name).max_by(&:length).length
        tasks.sort { |a, b| a.name <=> b.name }.each do |task|
          @output.puts "  #{task.name}".ljust(longest_name_length + 4) + Support::CLI.style.yellow(task.description) + "\n"
        end
      end

      def usage(task, describe: true)
        @output.puts task.help(describe: describe)
      end
    end
  end
end
