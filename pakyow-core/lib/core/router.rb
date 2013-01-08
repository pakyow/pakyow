module Pakyow
  class Router
    class << self
      # remove leading/trailing forward slashes
      def normalize_path(path)
        return path if path.is_a?(Regexp)

        path = path[1, path.length - 1] if path[0, 1] == '/'
        path = path[0, path.length - 1] if path[path.length - 1, 1] == '/'
        path
      end
    end

    def initialize
      @sets = {}
    end

    @@instance = self.new
    def self.instance
      @@instance
    end

    def set(name, &block)
      @sets[name] ||= RouteSet.new
      @sets[name].instance_exec(&block)
    end

    # Name based route lookup
    def route(name, group = nil)
      @sets.each { |set|
        if r = set[1].route(name, group)
          return r
        end
      }

      nil
    end

    # Name based function lookup
    def fn(name)
      @sets.each { |set|
        if f = set[1].fn(name)
          return f
        end
      }
    end

    # Finds route by path and calls each function in order
    def route!(request)
      self.trampoline(self.match(request))
    end

    def reroute!(request)
      throw :fns, self.router.match(request)
    end

    def handle!(name_or_code, from_logic = false)
      @sets.each { |set|
        if h = set[1].handle(name_or_code)
          Pakyow.app.response.status = h[0]
          from_logic ? throw(:fns, h[2]) : self.trampoline(h[2])
          break
        end
      }
    end

    def routed?
      @routed
    end

    def call_fns(fns)
      fns.each {|fn| self.context.instance_exec(&fn)}
    end

    #TODO this may be the thing that should be passed between
    #  middlewares, consisting of current req/res and access
    #  to helper methods.
    def context
      FnContext.new
    end

    protected

    def match(request)
      path   = Router.normalize_path(request.working_path)
      method = request.working_method

      @routed = false

      match, data = nil
      @sets.each { |set|
        match, data = set[1].match(path, method)
        break if match
      }

      fns = []
      if match
        fns = match[3]

        # handle route params
        #TODO where to do this?
        request.params.merge!(HashUtils.strhash(self.data_from_path(path, data, match[1])))

        #TODO where to do this?
        request.route_path = match[4]
      end

      fns
    end

    def trampoline(fns)
      until fns.empty?
        fns = catch(:fns) {
          self.call_fns(fns)

          # Getting here means that call() returned normally (not via a throw)
          :fall_through
        } # end :fns catch block

        # If reroute! or invoke_handler! was called in the block, block will have a new value (nil or block).
        # If neither was called, block will be :fall_through

        @routed = case fns
          when []             then false
          when :fall_through  then fns = [] and true
        end
      end
    end

    def data_from_path(path, matches, vars)
      data = {}
      return data unless matches

      vars.each {|v|
        data[v[:var]] = matches[v[:position]]
      }

      data
    end
  end
end

