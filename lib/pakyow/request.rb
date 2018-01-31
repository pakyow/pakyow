# frozen_string_literal: true

require "rack/request"

require "pakyow/support/indifferentize"
require "pakyow/support/inspectable"

module Pakyow
  # Pakyow's Request object.
  #
  class Request < Rack::Request
    using Support::Indifferentize

    # Contains the error object when request is in a failed state.
    #
    attr_accessor :error

    include Support::Inspectable
    inspectable :method, :params, :cookies

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
  end
end
