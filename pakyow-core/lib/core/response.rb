module Pakyow

  # The Response object.
  class Response < Rack::Response
    def initialize(*args)
      super

      self["Content-Type"] ||= 'text/html'
    end
  end
end
