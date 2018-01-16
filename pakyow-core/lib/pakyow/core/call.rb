# frozen_string_literal: true

module Pakyow
  class Call
    attr_reader :app, :request, :response

    def initialize(app, request, response)
      @app, @request, @response = app, request, response
      @processed, @handled_missing, @handled_failure = false
      @state = {}
    end

    def processed?
      @processed == true
    end

    def handled_missing?
      @handled_missing == true
    end

    def handled_failure?
      @handled_failure == true
    end

    def processed
      @processed = true
    end

    def handled_missing
      @handled_missing = true
    end

    def handled_failure
      @handled_failure = true
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
