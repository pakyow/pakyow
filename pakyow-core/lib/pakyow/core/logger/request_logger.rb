require 'securerandom'

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

      # @param type [Symbol] the type of request being logged (e.g. :http, :sock)
      # @param logger [Object] the object that will perform the logging
      # @param id [String] a unique id used to identify the request
      def initialize(type, logger: Pakyow.logger, id: SecureRandom.hex(4))
        @start = Time.now
        @logger = logger
        @type = type
        @id = id
      end

      %i(<< add debug error fatal info log unknown warn).each do |method|
        define_method method do |message|
          logger.send(method, decorate(message))
        end
      end

      # Logs the beginning of a request, including the time, request method,
      # request path, and ip address of the requester.
      #
      # @param env [Hash] the rack env for the request
      #
      def prologue(env)
        info({
          prologue: {
            time: start,
            method: env['REQUEST_METHOD'],
            path: env['REQUEST_PATH'],
            ip: env['REMOTE_ADDR'],
          }
        })
      end

      # Logs the conclusion of a request, including the response status.
      #
      # @param res [Array] the rack response array
      #
      def epilogue(res)
        info({
          epilogue: {
            status: res[0],
          }
        })
      end

      # Logs a problem encountered during the request, including the error
      # class, message, and backtrace.
      #
      # @param error [Object] the error object
      #
      def houston(error)
        error({
          error: {
            exception: error.class,
            message: error.to_s,
            backtrace: error.backtrace,
          }
        })
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
            type: type,
          },
        }.merge(message.is_a?(Hash) ? message : { message: message })
      end
    end
  end
end
