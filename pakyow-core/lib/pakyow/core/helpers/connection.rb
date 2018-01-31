# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Helpers
    module Connection
      extend Forwardable

      # @!method app
      #   Returns the current app.
      #
      #   @see App
      #
      # @!method request
      #   Returns the current request.
      #
      #   @see Request
      #
      # @!method response
      #   Returns the current response.
      #
      #   @see Response
      #
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
      def_delegators :@__connection, :app, :request, :response, :logger, :params, :session, :cookies

      alias req request
      alias res response

      # @!method config
      #   Delegates to {app}.
      #
      #   @see App#config
      def_delegators :app, :config

      # @!method path
      #   @return builds the path to a named route (see {Paths#path})
      #
      # @!method path_to
      #   @return builds the path to a route, following a trail of names (see {Paths#path_to})
      def_delegators :"app.paths", :path, :path_to
    end
  end
end
