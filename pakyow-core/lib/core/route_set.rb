module Pakyow
  class RouteSet
    include RouteMerger

    attr_reader :routes, :lookup

    def initialize
      @routes = {:get => [], :post => [], :put => [], :delete => []}
      @lookup = { :routes => {}, :grouped => {}}
      @handlers = []
      @fns = {}
      @templates = {}
    end

    def eval(&block)
      evaluator = RouteEval.new

      # default mixins
      evaluator.include(Pakyow::Routes::Restful)

      evaluator.eval(&block)
      merge(evaluator)
    end

    # Returns a route tuple:
    # [regex, vars, name, fns, path]
    #
    def match(path, method)
      path = StringUtils.normalize_path(path)

      @routes[method.to_sym].each{|r|
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
      }

      nil
    end

    def handle(name_or_code)
      @handlers.each{ |h|
        return h if h[0] == name_or_code || h[1] == name_or_code
      }

      nil
    end

    # Name based route lookup
    def route(name, group = nil)
      return @lookup[:routes][name] if group.nil?

      if grouped_routes = @lookup[:grouped][group]
        return grouped_routes[name]
      else
        #TODO error
      end
    end

    # Name based fn lookup
    def fn(name)
      return @fns[name]
    end
  end
end

