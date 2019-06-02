# frozen_string_literal: true

require "pakyow/support/cli/style"

require "pakyow/logger"

module Pakyow
  class Logger
    # Helpers for colorizing log messages.
    #
    module Colorizer
      # Colorizes message based on level.
      #
      def self.colorize(message, level)
        if color = color(level)
          Support::CLI.style.public_send(color, message)
        else
          message
        end
      end

      LEVEL_COLORS = {
        verbose: :magenta,
        debug: :cyan,
        info: :green,
        warn: :yellow,
        error: :red,
        fatal: :red
      }.freeze

      # Returns a color for a level.
      #
      def self.color(level)
        LEVEL_COLORS[level]
      end
    end
  end
end
