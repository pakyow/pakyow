# frozen_string_literal: true

require "forwardable"

module Pakyow
  class App
    module Helpers
      # Convenience methods for interacting with the connection object.
      #
      module Connection
        extend Forwardable

        attr_reader :connection

        # @!method app
        #   Returns the current app.
        #
        #   @see App
        # @!method logger
        #   Returns the logger.
        #
        #   @see Request#logger
        #
        # @!method params
        #   Returns the request params.
        #
        #   @see Request#params
        #
        # @!method session
        #   Returns the session.
        #
        #   @see Request#session
        #
        # @!method :cookies
        #   Returns cookies.
        #
        #   @see Request#:cookies
        def_delegators :connection, :app, :logger, :params, :session, :cookies

        # @!method operations
        #   Returns the operations lookup.
        #
        def_delegators :app, :operations
      end
    end
  end
end
