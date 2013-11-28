module Pakyow

  # The Response object.
  class Response < Rack::Response
    attr_reader :format

    def initialize(*args)
      super

      self["Content-Type"] ||= 'text/html'
    end

    def format=(format)
      @format = format
      self["Content-Type"] = Rack::Mime.mime_type(".#{format}")
    end
  end
end
