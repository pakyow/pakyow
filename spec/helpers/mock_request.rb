module Pakyow
  module SpecHelpers
    module MockRequest
      def mock_request(method = :get, path = "/", headers = {})
        Pakyow::Request.new({
          Rack::PATH_INFO => path,
          Rack::REQUEST_METHOD => method.to_s.upcase,
          Rack::RACK_INPUT => StringIO.new,
        }.merge(headers))
      end
    end
  end
end
