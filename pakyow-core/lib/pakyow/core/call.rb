# frozen_string_literal: true

module Pakyow
  class Call
    attr_reader :app, :request, :response

    def initialize(app, env)
      @app, @request, @response = app, Request.new(env), Response.new
      @processed, @halted = false, false
      @state = {}
    end

    def processed
      @processed = true
    end

    def processed?
      halted? || @processed == true
    end

    def halt
      @halted = true
    end

    def halted?
      @halted == true
    end

    def finalize
      @request.set_cookies(@response, @app.config.cookies)
      @response
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
