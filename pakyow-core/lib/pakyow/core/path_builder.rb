module Pakyow
  App.after :load do
    @path_builder = PathBuilder.new(self.class.router.instances)
  end

  # Builds paths to an app's routers.
  #
  class PathBuilder
    def initialize(routers)
      @routers = routers
    end

    # Builds the path to a named route.
    #
    # @example Build the path to the +new+ route within the +post+ group:
    #   path(:post_new)
    #   # => "/posts/new"
    #
    # @example Build the path providing a value for +post_id+:
    #   path(:post_edit, post_id: 1)
    #   # => "/posts/1/edit"
    #
    # @api public
    def path(name, **params)
      path_to(*name.to_s.split("_").map(&:to_sym), **params)
    end

    # Builds the path to a route, following a trail of names.
    #
    # @example Build the path to the +new+ route within the +post+ group:
    #   path_to(:post, :new)
    #   # => "/posts/new"
    #
    # @example Build the path providing a value for +post_id+:
    #   path_to(:post, :edit, post_id: 1)
    #   # => "/posts/1/edit"
    #
    # @api public
    def path_to(*names, **params)
      matched_routers = @routers.reject { |router_to_match|
        router_to_match.name.nil? || router_to_match.name != names.first
      }

      matched_routers.each do |matched_router|
        if path = matched_router.path_to(*names[1..-1], **params)
          return path
        end
      end

      nil
    end
  end
end
