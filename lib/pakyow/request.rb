require "rack/request"

require "pakyow/support/indifferentize"

module Pakyow
  # Pakyow's Request object.
  #
  # @api public
  class Request < Rack::Request
    using Pakyow::Support::Indifferentize

    # Contains the error object when request is in a failed state.
    #
    # @api public
    attr_accessor :error

    # TODO: a lot of the complexity in this object is due to rerouting
    # perhaps we can simplify things by creating a new request object
    # and providing access to the previous request via `parent`
    def initialize(*)
      super

      @env["CONTENT_TYPE"] = "text/html"
    end

    # Returns the request method (e.g. `:get`).
    #
    # @api public
    def method
      request_method.downcase.to_sym
    end

    # TODO: decide whether or not to keep this
    # if we do, should we do the rails thing and return mime type?
    # def format
    # end

    # Returns an indifferentized params hash.
    #
    # @api public
    def params
      # TODO: any reason not to just use rack.input?
      # @params.merge!(env['pakyow.data']) if env['pakyow.data'].is_a?(Hash)
      @params = super.indifferentize
    end

    # Returns an indifferentized cookie hash.
    #
    # @api public
    def cookies
      @cookies ||= super.indifferentize
    end
  end
end
