# frozen_string_literal: true

require "pastel"
require "tty-command"
require "tty-spinner"

module Pakyow
  module Support
    # Runs a command, or block of code, with consistent command-line messaging.
    #
    module CLI
      class Runner
        SPINNER = :dots
        FAILURE_MARK = "✕"
        SUCCESS_MARK = "✓"
        FAILURE_MESSAGE = "failed"
        SUCCESS_MESSAGE = ""

        def initialize(message:)
          @pastel = Pastel.new
          @spinner = TTY::Spinner.new(
            @pastel.bold(":spinner #{message}"),
            format: SPINNER,
            success_mark: SUCCESS_MARK,
            error_mark: FAILURE_MARK
          )

          @succeeded = @failed = false
        end

        # Runs a command or block of code. If a value for `command` is passed with
        # the block, the result will be yielded to the block on success.
        #
        def run(*command)
          puts
          @spinner.auto_spin

          if command.empty? && block_given?
            yield self
            succeeded
          else
            result = TTY::Command.new(printer: :null, pty: true).run!(*command)

            if result.failure?
              failed(result.err)
            else
              succeeded

              if block_given?
                yield result
              end
            end
          end
        end

        # Called when the command succeeds.
        #
        def succeeded(output = "")
          unless completed?
            @succeeded = true
            @spinner.success(@pastel.green(SUCCESS_MESSAGE))
            puts indent_output(output)
            puts unless output.empty?
          end
        end

        # Called when the command fails.
        #
        def failed(output = "")
          unless completed?
            @failed = true
            @spinner.error(@pastel.red(FAILURE_MESSAGE))
            puts indent_output(output)
            puts unless output.empty?
          end
        end

        # Returns `true` if the command has completed.
        #
        def completed?
          succeeded? || failed?
        end

        # Returns `true` if the command has completed successfully.
        #
        def succeeded?
          @succeeded == true
        end

        # Returns `true` if the command has completed unsuccessfully.
        #
        def failed?
          @failed == true
        end

        private

        ANSI_REGEX = /\x1B\[[0-9;]*[a-zA-Z]/

        def indent_output(output)
          output.split("\n").map { |line|
            first_real_string = line.split(ANSI_REGEX).reject(&:empty?).first
            line.sub(first_real_string.to_s, "   #{first_real_string}")
          }.join("\n")
        end
      end
    end
  end
end
