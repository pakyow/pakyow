module Pakyow
  # Helpers available anywhere
  #
  # @api public
  module Helpers
    def logger
      request.logger || Pakyow.logger
    end

    def request
      @request
    end
    alias :req :request

    def response
      @response
    end
    alias :res :response

    def params
      request ? request.params : {}
    end

    def session
      request ? request.session : {}
    end

    def cookies
      request ? request.cookies : {}
    end
  end
end
