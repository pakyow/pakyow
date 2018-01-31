# frozen_string_literal: true

require "forwardable"

require "pakyow/support/hookable"
require "pakyow/support/pipelined/haltable"

module Pakyow
  class Connection
    include Support::Hookable
    known_events :finalize

    include Support::Pipelined::Haltable

    attr_reader :app, :request, :response, :values

    def initialize(app, env)
      @app, @request, @response = app, Request.new(env), Response.new
      @initial_cookies = @request.cookies.dup
      @values = {}
    end

    def finalize
      performing :finalize do
        set_cookies; @response
      end
    end

    def set(key, value)
      @values[key] = value
    end

    def get(key)
      @values[key]
    end

    extend Forwardable
    def_delegators :request, :method, :format, :type, :host, :port, :ip, :user_agent, :base_url, :path,
                   :path_info, :script_name, :url, :params, :cookies, :session, :env, :logger, :ssl?

    def_delegators :response, :status, :status=, :write, :close, :body=

    def request_header?(key)
      @request.has_header?(key)
    end

    def request_header(key)
      @request.get_header(key)
    end

    def response_header?(key)
      @response.has_header?(key)
    end

    def response_header(key)
      @response.get_header(key)
    end

    def set_response_header(key, value)
      @response.add_header(key, value)
    end

    def delete_response_header(key)
      @response.delete_header(key)
    end

    protected

    # @api private
    def set_cookies
      config = @app.config.cookies

      @request.cookies.each_pair do |name, value|
        # delete the cookie if the value has been set to nil
        @response.delete_cookie(name) if value.nil?

        # cookie is already set with value, ignore
        next if @initial_cookies.include?(name) && @initial_cookies[name] == value

        # set cookie with defaults
        @response.set_cookie(name, path: config.path, expires: Time.now + config.expiry, value: value)
      end

      # delete cookies that were deleted from the request
      (@initial_cookies.keys - @request.cookies.keys).each do |name|
        @response.delete_cookie(name)
      end
    end
  end
end
