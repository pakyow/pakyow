module Pakyow

  # Helper methods that simply provide information (for use in binders)
  module GeneralHelpers
    def request
      Pakyow.app.request
    end
    
    def response
      Pakyow.app.response
    end
    
    def router
      RouteLookup.new
    end
  end

  # Helper methods specific to delegates and controllers.
  module Helpers
    include GeneralHelpers
    
    def app
      Pakyow.app
    end
  end
end
