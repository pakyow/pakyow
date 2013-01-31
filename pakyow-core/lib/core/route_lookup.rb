module Pakyow

  # Handles looking up paths for named routes and populating
  # the path with data.
  #
  class RouteLookup
    include Helpers

    def path(name, data = nil)
      route = self.get_named_route(name)
      data ? self.populate(route, data) : File.join('/', route[4])
    end

    def group(name)
      @group = name
      self
    end

    protected

    def get_named_route(name)
      Pakyow.app.router.route(name, @group) || []
    end

    def populate(route, data = {})
      vars  = route[1]
      
      split_path = Request.split_url(route[4])
      
      vars.each {|v|
        split_path[v[:position]] = data[v[:var]]
      }

      File.join('/', split_path.join('/'))
    end
  end
end
