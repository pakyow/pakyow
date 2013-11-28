require 'singleton'

module Pakyow
  # A singleton that manages route sets.
  #
  class Router
    include Singleton

    attr_reader :sets

    def initialize
      @sets = {}
    end

    #TODO want to do this for all sets?
    def reset
      @sets = {}
      self
    end

    # Creates a new set.
    #
    def set(name, &block)
      @sets[name] = RouteSet.new
      @sets[name].eval(&block)
    end

    # Iterates through route sets and returns the first matching route.
    #
    def route(name, group = nil)
      @sets.each { |set|
        if r = set[1].route(name, group)
          return r
        end
      }

      nil
    end

    # Performs the initial routing for a request.
    #
    def perform(context, app = Pakyow.app, &after_match)
      fns = match(context.request)
      after_match.call if block_given?

      trampoline(fns, app)
    end

    # Reroutes a request.
    #
    def reroute(request)
      throw :fns, self.match(request)
    end

    # Finds and invokes a handler by name or by status code.
    #
    def handle(name_or_code, app = Pakyow.app, from_logic = false)
      app.response.status = name_or_code if name_or_code.is_a?(Integer)

      @sets.each { |set|
        if h = set[1].handle(name_or_code)
          app.response.status = h[1]
          from_logic ? throw(:fns, h[2]) : self.trampoline(h[2], app)
          break
        end
      }
    end

    # Looks up and populates a path with data
    #
    def path(name, data = nil)
      RouteLookup.new.path(name, data)
    end

    # Looks up a route grouping
    #
    def group(name)
      RouteLookup.new.group(name)
    end

    # Calls a defined fn
    #
    def fn(name)
      @sets.each { |set|
        if fn = set[1].fn(name)
          fn.call
          break
        end
      }
    end

    protected

    # Calls a list of route functions in order (in a shared context).
    #
    def call_fns(fns, app)
      fns.each {|fn| app.instance_exec(&fn)}
    end

    # Finds the first matching route for the request path/method and
    # returns the list of route functions for that route.
    #
    def match(request)
      path   = Utils::String.normalize_path(request.path)
      method = request.method

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
        request.params.merge!(Utils::Hash.strhash(self.data_from_path(path, data, match[1])))

        #TODO where to do this?
        request.route_path = match[4]
      end

      fns
    end

    # Calls route functions and catches new functions as
    # they're thrown (e.g. by reroute).
    #
    def trampoline(fns, app)
      routed = false
      until fns.empty?
        fns = catch(:fns) {
          self.call_fns(fns, app)

          # Getting here means that call() returned normally (not via a throw)
          :fall_through
        } # end :fns catch block

        # If reroute! or invoke_handler! was called in the block, block will have a new value (nil or block).
        # If neither was called, block will be :fall_through

        routed = case fns
          when []             then false
          when :fall_through  then fns = [] and true
        end
      end

      return routed
    end

    # Extracts the data from a path.
    #
    def data_from_path(path, matches, vars)
      data = {}
      return data unless matches

      matches.names.each {|var|
        data[var.to_sym] = matches[var]
      }

      data
    end
  end
end
