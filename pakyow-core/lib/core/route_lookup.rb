module Pakyow

  # Handles looking up paths for named routes and populating
  # the path with data.
  #
  class RouteLookup
    include Helpers

    def path(name, data = nil)
      if route = get_named_route(name)
        data ? populate(route, data) : File.join('/', route[4])
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
        split_path[v[:url_position]] = data.delete(v[:var])
      }

      populated = File.join('/', split_path.join('/'))

      # add remaining data to query string
      unless data.empty?
        populated << '/?' + data.map { |k,v| "#{k}=#{v}" }.join('&')
      end

      return populated
    end
  end
end
