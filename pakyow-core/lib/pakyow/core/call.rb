# frozen_string_literal: true

require "pakyow/support/hookable"
require "pakyow/support/pipelined/haltable"

module Pakyow
  class Call
    include Support::Hookable
    known_events :finalize

    include Support::Pipelined::Haltable

    attr_reader :app, :request, :response

    def initialize(app, env)
      @app, @request, @response = app, Request.new(env), Response.new
      @state = {}
    end

    def finalize
      performing :finalize do
        @request.set_cookies(@response, @app.config.cookies)
        @response
      end
    end

    def set(key, value)
      @state[key] = value
    end

    def get(key)
      @state[key]
    end

    def values
      @state
    end
  end
end
