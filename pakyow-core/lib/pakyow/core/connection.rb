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
      @values = {}
    end

    def finalize
      performing :finalize do
        @request.set_cookies(@response, @app.config.cookies)
        @response
      end
    end

    def set(key, value)
      @values[key] = value
    end

    def get(key)
      @values[key]
    end

    extend Forwardable
    def_delegators :request, :method, :format, :host, :port, :ip, :user_agent, :base_url, :path,
                   :path_info, :script_name, :url, :params, :cookies, :session, :env, :logger

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
  end
end
