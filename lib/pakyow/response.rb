# frozen_string_literal: true

require "rack/response"

module Pakyow
  # Pakyow's response object.
  #
  # @api public
  class Response < Rack::Response
    # Returns the string representation for a status code.
    #
    # @example
    #   Pakyow::Request.nice_status(200)
    #   => "OK"
    #
    # @api public
    def self.nice_status(status_code)
      Rack::Utils::HTTP_STATUS_CODES[status_code] || "?"
    end

    # Sets the Content-Type header based on the format.
    #
    # @example
    #   request.format = :json
    #   request.content_type
    #   => "application/json"
    #
    # @api public
    def format=(format)
      self["Content-Type"] = Rack::Mime.mime_type(".#{format}")
    end

    # Returns the value of the Content-Type header.
    #
    # @api public
    def content_type
      self["Content-Type"]
    end
    alias type content_type
  end
end
