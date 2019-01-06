# frozen_string_literal: true

require "securerandom"

require "pakyow/connection"
require "pakyow/logger"

module Pakyow
  # Logs messages throughout a request / response lifecycle.
  #
  # Each request is expected to have its own RequestLogger instance, identified
  # by type (e.g. http, sock) and containing a unique id. Every log entry is
  # decorated with additional details about the request, including the request
  # method, uri, and ip address.
  #
  # In addition to logging standard messages, this class provides a way to log a
  # "prologue" and "epilogue" for the request. These special messages help tell
  # the full story for the request.
  #
  # Interact with RequestLogger as you would a normal log object, keeping in
  # mind that most of the work is delegated to the underlying logger object.
  #
  # @api private
  class RequestLogger
    # @!attribute [r] logger
    #   @return [Object] the object actually performing the logging
    attr_reader :logger

    # @!attribute [r] id
    #   @return [String] the unique id of the request being logged
    attr_reader :id

    # @!attribute [r] started_at
    #   @return [Time] the time when the request started
    attr_reader :started_at

    # @!attribute [r] type
    #   @return [Symbol] the type of request being logged
    attr_reader :type

    # @api private
    REQUEST_URI = "REQUEST_URI"

    # @param type [Symbol] the type of request being logged (e.g. :http, :sock)
    # @param started_at [Time] when the request began
    # @param logger [Object] the object that will perform the logging
    # @param id [String] a unique id used to identify the request
    def initialize(type, started_at: Time.now, logger: Pakyow.logger.dup, id: SecureRandom.hex(4))
      @type, @started_at, @logger, @id = type, started_at, logger, id
    end

    # Temporarily silences logs, up to +temporary_level+.
    #
    def silence(temporary_level = Logger::ERROR)
      original_level = @logger.level
      @logger.level = temporary_level
      yield
    ensure
      @logger.level = original_level
    end

    %i(<< debug error fatal info unknown warn).each do |method|
      define_method method do |message|
        logger.send(method, decorate(message))
      end
    end

    Logger::VERBOSE = -1
    def verbose(message)
      add(-1, message)
    end

    def add(severity, message)
      logger.add(severity, decorate(message))
    end
    alias log add

    # Logs the beginning of a request, including the time, request method,
    # request uri, and originating ip address.
    #
    # @param env [Hash] the rack env for the request
    #
    def prologue(connection)
      info(@logger.formatter.format_prologue(connection))
    end

    # Logs the conclusion of a request, including the response status.
    #
    # @param res [Array] the rack response array
    #
    def epilogue(connection)
      info(@logger.formatter.format_epilogue(connection))
    end

    # Logs an error raised when processing the request.
    #
    # @param error [Object] the error object
    #
    def houston(error)
      error(
        @logger.formatter.format_error(
          error
        )
      )
    end

    private

    def elapsed
      (Time.now - @started_at)
    end

    def decorate(message)
      @logger.formatter.format_message(
        message, id: id, type: type, elapsed: elapsed
      )
    end
  end
end
