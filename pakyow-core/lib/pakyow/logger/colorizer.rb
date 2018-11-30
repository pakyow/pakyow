# frozen_string_literal: true

require "pakyow/support/cli/style"

module Pakyow
  module Logger
    # Helpers for colorizing log messages.
    #
    module Colorizer
      # Colorizes message based on severity.
      #
      def self.colorize(message, severity)
        if color = color(severity)
          Support::CLI.style.public_send(color, message)
        else
          message
        end
      end

      LEVEL_COLORS = {
        "DEBUG" => :cyan,
        "INFO" => :green,
        "WARN" => :yellow,
        "ERROR" => :red,
        "FATAL" => :red
      }.freeze

      COLOR_TABLE = %i[
        black
        red
        green
        yellow
        blue
        magenta
        cyan
        white
      ].freeze

      # Returns a color for a level of severity.
      #
      def self.color(level)
        LEVEL_COLORS[level.to_s.upcase]
      end
    end
  end
end
