require "rack/request"

require "pakyow/support/indifferentize"

module Pakyow
  # The Request object.
  # TODO: a lot of the complexity in this object is due to rerouting
  # perhaps we can simplify things by creating a new request object
  # and providing access to the previous request via `parent`
  class Request < Rack::Request
    using Pakyow::Support::Indifferentize

    attr_accessor :route_path, :error

    def initialize(*)
      super

      @env["CONTENT_TYPE"] = "text/html"
    end

    def method
      request_method.downcase.to_sym
    end

    # TODO: decide whether or not to keep this
    # if we do, should we do the rails thing and return mime type?
    # def format
    # end

    def cookies
      @cookies ||= super.indifferentize
    end

    def params
      # TODO: any reason not to just use rack.input?
      # @params.merge!(env['pakyow.data']) if env['pakyow.data'].is_a?(Hash)
      @params = super.indifferentize
    end
  end
end
