require "rack/response"

module Pakyow

  # The Response object.
  class Response < Rack::Response
    def self.nice_status(status_code)
      Rack::Utils::HTTP_STATUS_CODES[status_code] || "?"
    end

    def format=(format)
      self["Content-Type"] = Rack::Mime.mime_type(".#{format}")
    end

    def content_type
      self["Content-Type"]
    end
    alias :type :content_type
  end
end
