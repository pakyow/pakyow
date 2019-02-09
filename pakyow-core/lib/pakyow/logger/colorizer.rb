# frozen_string_literal: true

require "log4r"

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
        Logger::NICE_LEVELS.key(:verbose) => :magenta,
        Logger::NICE_LEVELS.key(:debug) => :cyan,
        Logger::NICE_LEVELS.key(:info) => :green,
        Logger::NICE_LEVELS.key(:warn) => :yellow,
        Logger::NICE_LEVELS.key(:error) => :red,
        Logger::NICE_LEVELS.key(:fatal) => :red
      }.freeze

      # Returns a color for a level.
      #
      def self.color(level)
        LEVEL_COLORS[level]
      end
    end
  end
end
