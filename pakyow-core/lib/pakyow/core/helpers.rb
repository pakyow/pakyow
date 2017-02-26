module Pakyow
  # Helpers available anywhere
  #
  # @api public
  module Helpers
    def logger
      request.logger || Pakyow.logger
    end

    # TODO: I'd really like these to just be delegators
    # and not handle the missing request object
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
