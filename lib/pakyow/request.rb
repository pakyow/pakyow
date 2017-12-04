# frozen_string_literal: true

require "rack/request"

require "pakyow/support/indifferentize"

module Pakyow
  # Pakyow's Request object.
  #
  class Request < Rack::Request
    using Support::Indifferentize

    # Contains the error object when request is in a failed state.
    #
    attr_accessor :error

    def initialize(*args)
      super

      @initial_cookies = cookies.dup
    end

    # Returns the request method (e.g. `:get`).
    #
    def method
      @method ||= request_method.downcase.to_sym
    end

    # Returns the symbolized format of the request.
    #
    # @example
    #   request.format
    #   => :html
    #
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
    def params
      # TODO: any reason not to just use rack.input?
      # @params.merge!(env['pakyow.data']) if env['pakyow.data'].is_a?(Hash)
      @params ||= super.deep_indifferentize
    end

    # Returns an indifferentized cookie hash.
    #
    def cookies
      @cookies ||= super.indifferentize
    end

    # @api private
    def set_cookies(response, config)
      cookies.each_pair do |name, value|
        # delete the cookie if the value has been set to nil
        response.delete_cookie(name) if value.nil?

        # cookie is already set with value, ignore
        next if @initial_cookies.include?(name) && @initial_cookies[name] == value

        # set cookie with defaults
        response.set_cookie(name, path: config.path, expires: Time.now + config.expiry, value: value)
      end

      # delete cookies that were deleted from the request
      (@initial_cookies.keys - cookies.keys).each do |name|
        response.delete_cookie(name)
      end
    end
  end
end
