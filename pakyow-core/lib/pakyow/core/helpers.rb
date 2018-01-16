# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"

module Pakyow
  # Methods available to endpoints.
  #
  module Helpers
    include Support::SafeStringHelpers

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
    def_delegators :@__state, :app, :request, :response

    alias req request
    alias res response

    # @!method config
    #   Delegates to {app}.
    #
    #   @see App#config
    def_delegators :app, :config

    # @!method logger
    #   Delegates to {request}.
    #
    #   @see Request#logger
    #
    # @!method params
    #   Delegates to {request}.
    #
    #   @see Request#params
    #
    # @!method session
    #   Delegates to {request}.
    #
    #   @see Request#session
    #
    # @!method :cookies
    #   Delegates to {request}.
    #
    #   @see Request#:cookies
    def_delegators :request, :logger, :params, :session, :cookies

    # @!method path
    #   @return builds the path to a named route (see {Paths#path})
    #
    # @!method path_to
    #   @return builds the path to a route, following a trail of names (see {Paths#path_to})
    def_delegators :"app.paths", :path, :path_to

    def expose(name, default_value = default_omitted = true)
      raise ArgumentError, "name must a symbol" unless name.is_a?(Symbol)

      value = if block_given?
        yield
      elsif default_omitted
        __send__(name)
      end

      unless default_omitted
        value ||= default_value
      end

      @__state.set(name, value)
    end
  end
end
