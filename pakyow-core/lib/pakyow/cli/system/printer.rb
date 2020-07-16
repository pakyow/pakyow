# frozen_string_literal: true

require "tty/command"

module Pakyow
  class CLI
    module System
      # @api private
      class Printer < TTY::Command::Printers::Abstract
        def initialize(*, **)
          super

          @buffer = String.new
        end

        def print_command_start(cmd, *args)
          output.info("running: " + cmd.to_command + args.join)
        end

        def print_command_out_data(cmd, *args)
          entry = args.join(" ")

          if args.last.end_with?("\n")
            output.info(@buffer + entry)

            @buffer.clear
          else
            @buffer << entry
          end
        end

        def print_command_err_data(cmd, *args)
          output.error(args.join(" "))
        end

        def print_command_exit(cmd, *args)
          @buffer = String.new
        end
      end
    end
  end
end
