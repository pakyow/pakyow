# frozen_string_literal: true

require "securerandom"

require "console/filter"

require "pakyow/support/deprecatable"

module Pakyow
  # Logs messages throughout the lifetime of an environment, connection, etc.
  #
  # In addition to logging standard messages, this class provides a way to log a `prologue` and
  # `epilogue` for a connection, as well as a `houston` method for logging errors.
  #
  class Logger < Console::Filter[internal: 0, debug: 1, info: 2, warn: 3, error: 4, fatal: 5, unknown: 6]
    class << self
      # Returns a logger that captures no output.
      #
      def null
        new(:null, output: StringIO.new, level: :off)
      end
    end

    extend Support::Deprecatable

    require_relative "logger/colorizer"
    require_relative "logger/timekeeper"

    # @!attribute [r] id
    #   @return [String] the unique id of the logger instance
    attr_reader :id

    # @!attribute [r] started_at
    #   @return [Time] the time when logging started
    attr_reader :started_at

    # @!attribute [r] type
    #   @return [Symbol] the type of logger
    attr_reader :type

    # @param type [Symbol] the type of logging being done (e.g. :http, :sock)
    # @param started_at [Time] when the logging began
    # @param output [Object] the object that will perform the logging
    # @param id [String] a unique id used to identify the request
    def initialize(type, output:, level:, started_at: Time.now, id: SecureRandom.hex(4))
      @type, @started_at, @id = type, started_at, id

      level = case level
      when :all, "all"
        0
      when :off, "off"
        7
      when Symbol, String
        self.class.const_get(:LEVELS)[level.to_sym]
      else
        level
      end

      super(output, level: level)
    end

    LEVELS.keys.each do |method|
      class_eval <<~CODE, __FILE__, __LINE__ + 1
        def #{method}(message = nil, &block)
          super(message) { decorate(message, &block) }
        end
      CODE
    end

    def <<(message)
      add(:unknown, message)
    end

    def add(level, message = nil, &block)
      public_send(level, message, &block)
    end
    alias_method :log, :add

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

    def decorate(message = nil)
      message = yield if block_given?
      {"logger" => self, "message" => message}
    end

    def formatted_prologue(connection)
      {"prologue" => connection}
    end

    def formatted_epilogue(connection)
      {"epilogue" => connection}
    end

    def formatted_error(error)
      {"error" => error}
    end
  end
end
