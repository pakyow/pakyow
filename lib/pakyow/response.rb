# frozen_string_literal: true

require "rack/response"

require "pakyow/support/inspectable"

module Pakyow
  # Pakyow's response object.
  #
  class Response < Rack::Response
    include Support::Inspectable
    inspectable :status, :body

    # Returns the string representation for a status code.
    #
    # @example
    #   Pakyow::Request.nice_status(200)
    #   => "OK"
    #
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
    def format=(format)
      self["Content-Type"] = Rack::Mime.mime_type(".#{format}")
    end

    # Returns the value of the Content-Type header.
    #
    def content_type
      self["Content-Type"]
    end
    alias type content_type
  end
end
