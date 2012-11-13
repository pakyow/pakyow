module Pakyow
  class RouteSet
    def initialize
      @routes = {:get => [], :post => [], :put => [], :delete => []}

      @routes_by_name = {}
      @grouped_routes_by_name = {}

      @funcs  = {}
      @groups = {}

      @templates = {}

      @handlers = []

      @scope  = {:name => nil, :path => '/', :hooks => {:before => [], :after => []}}
    end

    def match(path, method)
      path = Router.normalize_path(path)

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
      return @routes_by_name[name] unless group

      if grouped_routes = @grouped_routes_by_name[group]
        grouped_routes[name]
      end
    end

    # Creates or retreivs a named func
    def fn(name, &block)
      @funcs[name] = block and return if block

      [@funcs[name]]
    end

    def handler(name, *args, &block)
      code, fn = args

      fn = code and code = nil if code.is_a?(Proc)
      fn = block if block_given?

      @handlers << [name, code, [fn]]
    end

    def default(*args, &block)
      self.register_route(:get, '/', *args, &block)
    end

    def get(*args, &block)
      self.register_route(:get, *args, &block)
    end

    def put(*args, &block)
      self.register_route(:put, *args, &block)
    end

    def post(*args, &block)
      self.register_route(:post, *args, &block)
    end

    def delete(*args, &block)
      self.register_route(:delete, *args, &block)
    end
    
    def call(controller, action)
      lambda {
        controller = Object.const_get(controller)
        action ||= Configuration::Base.app.default_action

        instance = controller.new
        request.controller  = instance
        request.action      = action

        instance.send(action)
      }
    end

    def group(name, *args, &block)
      # deep clone existing hooks to reset at the close of this group
      original_hooks = Marshal.load(Marshal.dump(@scope[:hooks]))
      
      @scope[:hooks] = self.merge_hooks(@scope[:hooks], args[0]) if @scope[:hooks] && args[0]

      @scope[:name] = name
      @groups[name] = []
      @grouped_routes_by_name[name] = {}

      self.instance_exec(&block)
      @scope[:name] = nil
      
      @scope[:hooks] = original_hooks
    end

    def namespace(path, *args, &block)
      name, hooks = args
      hooks = name if name.is_a?(Hash)

      original_path  = @scope[:path]
      @scope[:path] = File.join(@scope[:path], path)
      
      self.group(name, hooks || {}, &block)
      @scope[:path] = original_path
    end

    def template(name, &block)
      @templates[name] = block
    end

    def expand(t_name, g_name, path = nil, data = nil, &block)
      data = path and path = nil if path.is_a?(Hash)

      # evaluate block in context of some class that implements
      # method_missing to store map of functions 
      # (e.g. index, show)
      t = RouteTemplate.new(block, g_name, path, self)

      # evaluate template in same context, where func looks up funcs
      # from map and extends get (and others) to add proper names
      t.expand(@templates[t_name], data)
    end
    
    def merge_hooks(h1, h2)
      # normalize
      h1[:before]  ||= []
      h1[:after]   ||= []
      h1[:around]  ||= []
      h2[:before]  ||= []
      h2[:after]   ||= []
      h2[:around]  ||= []

      # merge
      h1[:before].concat(h2[:before])
      h1[:after].concat(h2[:after])
      h1[:around].concat(h2[:around])
      h1
    end

    protected

    def register_route(method, path, *args, &block)
      name, fns, hooks = self.parse_route_args(args)

      fns ||= []
      # add passed block to fns
      fns << block if block_given?
      
      hooks = self.merge_hooks(hooks || {}, @scope[:hooks])

      # build the final list of fns
      fns = self.build_fns(fns, hooks)

      # prepend scope path if we're in a scope
      path = File.join(@scope[:path], path)
      path = Router.normalize_path(path)
      
      # get regex and vars for path
      regex, vars = self.build_route_matcher(path)

      # create the route tuple
      route = [regex, vars, name, fns, path]

      @routes[method] << route
      @routes_by_name[name] =  route

      # store group references if we're in a scope
      return unless group = @scope[:name]
      @groups[group] << route
      @grouped_routes_by_name[group][name] = route
    end

    def parse_route_args(args)
      ret = []
      args.each { |arg|
        if arg.is_a?(Hash) # we have hooks
          ret[2] = arg
        elsif arg.is_a?(Array) # we have fns
          ret[1] = arg
        elsif arg.is_a?(Proc) # we have a fn
          ret[1] = [arg]
        else # we have a name
          ret[0] = arg
        end
      }
      ret
    end
    
    def build_fns(main_fns, hooks)
      fns = []

      fns.concat(hooks[:around])  if hooks && hooks[:around]
      fns.concat(hooks[:before])  if hooks && hooks[:before]
      fns.concat(main_fns)        if main_fns
      fns.concat(hooks[:after])   if hooks && hooks[:after]
      fns.concat(hooks[:around])  if hooks && hooks[:around]
      
      fns
    end

    def build_route_matcher(path)
      return path, [] if path.is_a?(Regexp)

      # check for vars
      return path, [] unless path[0,1] == ':' || path.index('/:')
      
      # we have vars
      vars = []
      position_counter = 1
      regex_route = path
      route_segments = path.split('/')
      route_segments.each_with_index { |segment, i|
        if segment.include?(':')
          vars << { :position => position_counter, :var => segment.gsub(':', '').to_sym }
          if i == route_segments.length-1 then
            regex_route = regex_route.sub(segment, '((\w|[-.~:@!$\'\(\)\*\+,;])*)')
            position_counter += 2
          else
            regex_route = regex_route.sub(segment, '((\w|[-.~:@!$\'\(\)\*\+,;])*)')
            position_counter += 2
          end
        end
      }
      reg = Regexp.new("^#{regex_route}$")
      return reg, vars
    end
  end
end

