module Pakyow

  # For methods that should be accessible anywhere
  module Helpers
    def logger
      request.logger
    end

    def router
      RouteLookup.new
    end

    def request
      @context.request
    end
    alias_method :req, :request

    def response
      @context.response
    end
    alias_method :res, :response

    def params
      request.params
    end

    def session
      request.session
    end

    def cookies
      request.cookies
    end

    def config
      Pakyow::Config::Base
    end
  end

  # For methods that should only be accessible through App
  module AppHelpers; end
end
