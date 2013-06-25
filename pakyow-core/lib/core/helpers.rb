module Pakyow

  # Helper methods that simply provide information (for use in binders)
  module GeneralHelpers
    def router
      RouteLookup.new
    end

    def request
      @request
    end
    alias_method :req, :request

    def response
      @response
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

  # Helper methods specific to delegates and controllers.
  module Helpers
    include GeneralHelpers
  end
end
