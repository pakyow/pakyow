module Pakyow
  # Helpers available anywhere
  #
  # @api public
  module Helpers
    def context
      @context or raise NoContextError
    end

    def logger
      request.logger || Pakyow.logger
    end

    def router
      RouteLookup.new
    end

    def request
      context ? context.request : nil
    end
    alias_method :req, :request

    def response
      context ? context.response : nil
    end
    alias_method :res, :response

    def params
      request ? request.params : {}
    end

    def session
      request ? request.session : {}
    end

    def cookies
      request ? request.cookies : {}
    end

    def config
      Pakyow::Config
    end

    # Returns the primary app environment.
    #
    # @api public
    def env
      config.env
    end
  end
end
