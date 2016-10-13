module Pakyow
  class RouteSet
    include RouteMerger

    attr_reader :routes, :lookup

    def initialize(name = nil)
      @routes = {:get => [], :post => [], :put => [], :patch => [], :delete => []}
      @lookup = { :routes => {}, :grouped => {}}
      @handlers = []
      @fns = {}
      @templates = {}

      Router.instance.sets[name] = self
    end

    def instance_eval(&block)
      evaluator = RouteEval.with_defaults
      evaluator.eval(&block)
      merge(evaluator)
    end

    # Returns a route tuple:
    # [regex, vars, name, fns, path]
    #
    def match(path, method)
      path = String.normalize_path(path)

      # want the request to still knows it's a head, but match as get
      method = method.to_sym
      method = :get if method == :head

      (@routes[method] || []).each do |r|
        #TODO can we do this without conditionals? fall-through?
        case r[0]
        when Regexp
          if data = r[0].match(path)
            return r, data
          end
        when String
          if r[0] == path
            return r, nil
          end
        end
      end

      nil
    end

    def handle(name_or_code)
      @handlers.each{ |h|
        return h if h[0] == name_or_code || h[1] == name_or_code
      }

      #TODO raise error
      nil
    end

    # Name based route lookup
    def route(name, group = nil)
      return @lookup[:routes][name] if group.nil?

      if grouped_routes = @lookup[:grouped][group]
        return grouped_routes[name]
      else
        #TODO error (perhaps a set-specific exception rescued by router)
      end
    end

    # Name based fn lookup
    def fn(name)
      return @fns[name]
    end
  end
end

