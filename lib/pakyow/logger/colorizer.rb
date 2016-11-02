module Pakyow
  module Logger
    # Helpers for colorizing log messages.
    #
    module Colorizer
      # Colorizes message based on severity.
      #
      def self.colorize(message, severity)
        return message unless color = color(severity)
        COLOR_SEQ % (30 + COLOR_TABLE.index(color)) + (message || "") + RESET_SEQ
      end

      private_class_method

      LEVEL_COLORS = {
        "DEBUG" => :cyan,
        "INFO"  => :green,
        "WARN"  => :yellow,
        "ERROR" => :red,
        "FATAL" => :red
      }.freeze

      COLOR_TABLE = [
        :black,
        :red,
        :green,
        :yellow,
        :blue,
        :magenta,
        :cyan,
        :white
      ].freeze

      RESET_SEQ = "\033[0m".freeze
      COLOR_SEQ = "\033[%dm".freeze

      # Returns a color for a level of severity.
      #
      def self.color(level)
        LEVEL_COLORS[level.to_s.upcase]
      end
    end
  end
end
