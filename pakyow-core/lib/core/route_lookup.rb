module Pakyow

  # Handles looking up paths for named routes and populating
  # the path with data.
  #
  class RouteLookup
    include Helpers

    def path(name, data = nil)
      if route = self.get_named_route(name)
        data ? self.populate(route, data) : File.join('/', route[4])
      end
    end

    def group(name)
      @group = name
      self
    end

    protected

    def get_named_route(name)
      if defined? @group
        Router.instance.route(name, @group)
      else
        Router.instance.route(name)
      end
    end

    def populate(route, data = {})
      vars  = route[1]
      
      split_path = Request.split_url(route[4])
      
      vars.each {|v|
        split_path[v[:url_position]] = data[v[:var]]
      }

      File.join('/', split_path.join('/'))
    end
  end
end
