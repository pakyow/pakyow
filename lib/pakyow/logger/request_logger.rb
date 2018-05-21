# frozen_string_literal: true

require "securerandom"
require "logger"

require "pakyow/connection"

module Pakyow
  module Logger
    # Logs messages throughout a request / response lifecycle.
    #
    # Each call to the app is expected to have its own RequestLogger instance,
    # identified by type (e.g. http, sock) and containing a unique id. Every
    # log entry will be decorated with additional details about the request.
    # In addition to logging standard messages, this class provides a way to
    # log the prologue and epilogue of a request / response lifecycle. These
    # messages help tell the full story for the request. Finally, this class
    # provides a way to log errors that occur.
    #
    # Interact with RequestLogger exactly like a normal log object, keeping
    # in mind that the actual responsibility of logging is delegated to the
    # logger object passed to the initializer.
    #
    # @api private
    class RequestLogger
      # @!attribute [r] logger
      #   @return [Object] the object actually performing the logging
      attr_reader :logger

      # @!attribute [r] id
      #   @return [String] the unique id of the request being logged
      attr_reader :id

      # @!attribute [r] start
      #   @return [Time] the time when the request started
      attr_reader :start

      # @!attribute [r] type
      #   @return [Symbol] the type of request being logged
      attr_reader :type

      # @api private
      REQUEST_URI = "REQUEST_URI".freeze

      # @param type [Symbol] the type of request being logged (e.g. :http, :sock)
      # @param logger [Object] the object that will perform the logging
      # @param id [String] a unique id used to identify the request
      def initialize(type, logger: Pakyow.logger.dup, id: SecureRandom.hex(4))
        @start = Time.now
        @logger = logger
        @type = type
        @id = id
      end

      # Temporarily silences logs, up to +temporary_level+.
      #
      def silence(temporary_level = ::Logger::ERROR)
        original_level = @logger.level
        @logger.level = temporary_level
        yield
      ensure
        @logger.level = original_level
      end

      %i(<< add debug error fatal info log unknown warn).each do |method|
        define_method method do |message|
          logger.send(method, decorate(message))
        end
      end

      ::Logger::VERBOSE = -1
      def verbose(message)
        logger.add(-1, decorate(message))
      end

      # Logs the beginning of a request, including the time, request method,
      # request uri, and ip address of the requester.
      #
      # @param env [Hash] the rack env for the request
      #
      def prologue(env)
        info(prologue: {
               time: start,
               method: env[Rack::REQUEST_METHOD],
               uri: env[REQUEST_URI],
               ip: Rack::Request.new(env).ip
             })
      end

      # Logs the conclusion of a request, including the response status.
      #
      # @param res [Array] the rack response array
      #
      def epilogue(res)
        info(epilogue: {
               status: res.to_a[0]
             })
      end

      # Logs an error raised when processing the request.
      #
      # @param error [Object] the error object
      #
      def houston(error)
        error(error: error)
      end

      private

      def elapsed
        (Time.now - start)
      end

      def decorate(message)
        {
          elapsed: elapsed,
          request: {
            id: id,
            type: type
          }
        }.merge(message.is_a?(Hash) ? message : { message: message })
      end
    end
  end
end
