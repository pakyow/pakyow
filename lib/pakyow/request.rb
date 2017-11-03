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

    # Contains the route path that was matched for the request.
    #
    # @api public
    attr_accessor :route_path

    # Returns the request method (e.g. `:get`).
    #
    # @api public
    def method
      request_method.downcase.to_sym
    end

    # Returns the symbolized format of the request.
    #
    # @example
    #   request.format
    #   => :html
    #
    # @api public
    def format
      return @format if defined?(@format)

      if path.include?(".")
        @format = path.split(".").last.to_sym
      else
        @format = :html
      end
    end

    # Returns an indifferentized params hash.
    #
    # @api public
    def params
      # TODO: any reason not to just use rack.input?
      # @params.merge!(env['pakyow.data']) if env['pakyow.data'].is_a?(Hash)
      @params ||= super.indifferentize
    end

    # Returns an indifferentized cookie hash.
    #
    # @api public
    def cookies
      @cookies ||= super.indifferentize
    end
  end
end
