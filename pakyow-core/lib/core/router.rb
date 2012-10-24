module Pakyow
  class Router
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

    @@instance = self.new
    def self.instance
      @@instance
    end

    # Finds route by path and calls each function in order
    def route!(request)
      path   = request.working_path
      method = request.working_method

      @routed = false
      return unless match = self.find_match(path, method)
      
      # handle route params
      #TODO where to do this?
      request.params.merge!(HashUtils.strhash(self.data_from_path(path, match[1])))

      #TODO where to do this?
      request.route_path = match[4]

      self.trampoline(match[3])
    end

    def reroute!(request)
      path   = request.working_path
      method = request.working_method

      fns = ((match = self.find_match(path, method)) ? match[3] : [] )

      #TODO where to do this?
      request.params.merge!(HashUtils.strhash(self.data_from_path(path, match[1])))
      
      #TODO where to do this?
      request.route_path = match[4]

      throw :reroute, fns
    end

    def routed?
      @routed
    end

    def handle!(name_or_code)
      @handlers.each{ |h| 
        self.trampoline(h[2]) and break if h[0] == name_or_code || h[1] == name_or_code
      }
    end

    # Name based route lookup
    def route(name, group = nil)
      return @routes_by_name[name] unless group

      if grouped_routes = @grouped_routes_by_name[group]
        grouped_routes[name]
      end
    end

    # Creates or retreivs a named func
    def func(name, &block)
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
      original_hooks = @scope[:hooks]
      @scope[:hooks] = self.merge_hooks(@scope[:hooks], args[0]) if @scope[:hooks] && args[0]

      # name = args[0]
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

    def expand(name, path, &block)
      #TODO path shouldn't be required (creates a group if left out)

      # evaluate block in context of some class that implements
      # method_missing to store map of functions 
      # (e.g. index, show)
      t = RouteTemplate.new(block, path, self)

      # evaluate template in same context, where func looks up funcs
      # from map and extends get (and others) to add proper names
      t.expand(@templates[name])
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
      path = self.normalize_path(path)
      
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

    def find_match(path, method)
      path = self.normalize_path(path)
      @routes[method.to_sym].select{|r| r[0].is_a?(Regexp) ? r[0].match(path) : r[0] == path}[0]
    end

    def trampoline(fns)
      until fns.empty?
        fns = catch(:reroute) {
          self.call_fns(fns)
          
          # Getting here means that call() returned normally (not via a throw)
          :fall_through
        } # end :reroute catch block

        # If reroute! or invoke_handler! was called in the block, block will have a new value (nil or block).
        # If neither was called, block will be :fall_through

        @routed = case fns
          when []             then false
          when :fall_through  then fns = [] and true
        end

        # we're done here
        next if fns.empty?
        
        begin
          # caught by other middleware (e.g. presenter)
          throw :rerouted, Pakyow.app.request
        rescue ArgumentError
        end
      end
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

    # remove leading/trailing forward slashes
    def normalize_path(path)
      return path if path.is_a?(Regexp)

      path = path[1, path.length - 1] if path[0, 1] == '/'
      path = path[0, path.length - 1] if path[path.length - 1, 1] == '/'
      path
    end

    def data_from_path(path, vars)
      data = {}
      vars.each {|v|
        data[v[:var]] = Pakyow.app.request.path_parts[v[:position]]
      }

      data
    end
  end


  class RouteTemplate
    attr_accessor :path

    def initialize(block, path, router)
      @fns    = {}
      @path   = path
      @router = router

      self.instance_exec(&block)
    end

    def action(method, *args, &block)
      fns = block_given? ? [block] : args[0]
      @fns[method] = fns
    end

    def expand(template)
      @expanding = true
      self.instance_exec(&template)
    end

    def func(name)
      @expanding ? @fns[name] : @router.func(name)
    end

    def call(controller, action)
      @router.call(controller, action)
    end

    def get(path, *args, &block)
      @router.get(File.join(@path, path), *args, &block)
    end

    def put(path, *args, &block)
      @router.put(File.join(@path, path), *args, &block)
    end

    def post(path, *args, &block)
      @router.post(File.join(@path, path), *args, &block)
    end

    def delete(path, *args, &block)
      @router.delete(File.join(@path, path), *args, &block)
    end

    #TODO best name?
    def map_actions(controller, actions)
      actions.each { |a|
        self.action(a, self.call(controller, a))
      }
    end

    #TODO best name?
    def map_restful_actions(controller)
      self.map_actions(controller, self.restful_actions)
    end

    def restful_actions
      [:index, :show, :new, :create, :edit, :update, :delete]
    end
  end
end
