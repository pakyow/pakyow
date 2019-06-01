# frozen_string_literal: true

require "log4r"
require "securerandom"

module Pakyow
  # Logs messages throughout the lifetime of an environment, connection, etc.
  #
  # In addition to logging standard messages, this class provides a way to log a `prologue` and
  # `epilogue` for a connection, as well as a `houston` method for logging errors.
  #
  class Logger
    LEVELS = %i(
      all
      verbose
      debug
      info
      warn
      error
      fatal
      unknown
      off
    ).freeze

    LOGGED_LEVELS = LEVELS.dup
    LOGGED_LEVELS.delete(:all)
    LOGGED_LEVELS.delete(:off)
    LOGGED_LEVELS.freeze

    NICE_LEVELS = Hash[LEVELS.map.with_index { |level, i|
      [i + 1, level]
    }].freeze

    require "pakyow/logger/colorizer"
    require "pakyow/logger/timekeeper"

    # @!attribute [r] id
    #   @return [String] the unique id of the logger instance
    attr_reader :id

    # @!attribute [r] started_at
    #   @return [Time] the time when logging started
    attr_reader :started_at

    # @!attribute [r] type
    #   @return [Symbol] the type of logger
    attr_reader :type

    # @!attribute [r] level
    #   @return [Integer] the current log level
    attr_reader :level

    # @!attribute [r] output
    #   @return [Symbol] where log entries are written
    attr_reader :output

    # @param type [Symbol] the type of logging being done (e.g. :http, :sock)
    # @param started_at [Time] when the logging began
    # @param output [Object] the object that will perform the logging
    # @param id [String] a unique id used to identify the request
    def initialize(type, started_at: Time.now, output: Pakyow.global_logger, id: SecureRandom.hex(4), level: output.level)
      @type, @started_at, @output, @id, @level = type, started_at, output, id

      @level = case level
      when Integer
        level
      else
        NICE_LEVELS.key(level)
      end
    end

    # Temporarily silences logs, up to +temporary_level+.
    #
    def silence(temporary_level = :error)
      original_level = @level
      @level = NICE_LEVELS.key(temporary_level)
      yield
    ensure
      @level = original_level
    end

    LOGGED_LEVELS.each do |method|
      class_eval <<~CODE, __FILE__, __LINE__ + 1
        def #{method}(message = nil, &block)
          if log?(#{NICE_LEVELS.key(method)})
            @output.#{method} { decorate(message, &block) }
          end
        end
      CODE
    end

    def <<(message)
      if log?(8)
        add(:unknown, message)
      end
    end

    def add(level, message = nil, &block)
      if log?(NICE_LEVELS.key(level))
        @output.public_send(level) { decorate(message, &block) }
      end
    end
    alias log add

    # Logs the beginning of a request, including the time, request method,
    # request uri, and originating ip address.
    #
    # @param env [Hash] the rack env for the request
    #
    def prologue(connection)
      info { formatted_prologue(connection) }
    end

    # Logs the conclusion of a request, including the response status.
    #
    # @param res [Array] the rack response array
    #
    def epilogue(connection)
      info { formatted_epilogue(connection) }
    end

    # Logs an error raised when processing the request.
    #
    # @param error [Object] the error object
    #
    def houston(error)
      error { formatted_error(error) }
    end

    def elapsed
      (Time.now - @started_at)
    end

    private

    def log?(level)
      level >= @level
    end

    def decorate(message = nil)
      message = yield if block_given?
      { "logger" => self, "message" => message }
    end

    def formatted_prologue(connection)
      { "prologue" => connection }
    end

    def formatted_epilogue(connection)
      { "epilogue" => connection }
    end

    def formatted_error(error)
      { "error" => error }
    end
  end
end
