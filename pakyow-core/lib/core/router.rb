
#TODO route path lookups
#TODO other methods (head, default)
#TODO confirm param order (e.g. namespace)
#TODO around hooks
#TODO route aliases
#TODO document
#TODO check in!

module Pakyow
  class Router
    #TODO singleton
    def initialize
      @routes = {:get => [], :post => [], :put => [], :delete => []}
      @funcs  = {}
      @groups = {}

      @templates = {}

      @handlers = []

      @scope  = {:name => nil, :path => '/', :hooks => {:before => [], :after => []}}
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

    # Creates vector of functions (hooks and main) to be called in order
    def func(name, hooks = nil, &block)
      @funcs[name] = block and return if block

      self.build_fns([@funcs[name]], hooks)
    end

    def handler(name, *args, &block)
      code, fn = args

      #TODO need a better way of handling incoming params; this sucks
      fn = code and code = nil if code.is_a?(Proc)
      fn = block if block_given?

      @handlers << [name, code, [fn]]
    end

    # def get(path, *args, &block)
    def get(*args)
      self.register_route(:get, *args)
      # return
      # name, main_fns = args

      # # necessary because names are optional and func could be passed in its place
      # main_fns = name and name = nil if name.is_a?(Proc) || name.is_a?(Array)

      # # handle function passed as block
      # main_fns ||= block
      # main_fns = [main_fns] unless main_fns.is_a?(Array)

      # regex, vars = build_route_matcher(self.normalize_path(File.join(@scope[:path], path)))
      # route = [regex, vars, name, self.build_fns(main_fns, @scope[:hooks]), path]
      # @routes[:get] << route

      # @groups[@scope[:name]] << route if @scope[:name]
    end

    def put(*args)
      self.register_route(:put, *args)
    end

    def post(*args)
      self.register_route(:post, *args)
    end

    def delete(*args)
      self.register_route(:delete, *args)
    end

    def register_route(method, path, *args, &block)
      name, main_fns = args

      # necessary because names are optional and func could be passed in its place
      main_fns = name and name = nil if name.is_a?(Proc) || name.is_a?(Array)

      # handle function passed as block
      main_fns ||= block
      main_fns = [main_fns] unless main_fns.is_a?(Array) || main_fns.nil?
      
      regex, vars = build_route_matcher(self.normalize_path(File.join(@scope[:path], path)))
      route = [regex, vars, name, self.build_fns(main_fns, @scope[:hooks]), path]
      @routes[method] << route

      @groups[@scope[:name]] << route if @scope[:name]
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
      @scope[:hooks] = self.merge_hooks(@scope[:hooks], args[0])

      name = args[0]
      @scope[:name] = name
      @groups[name] = []

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

    #TODO why can't this be protected?
    def call_fns(fns)
      fns.each {|fn| Pakyow.app.instance_exec(&fn)}
    end

    protected

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

      fns.concat(hooks[:before])  if hooks && hooks[:before]
      fns.concat(main_fns)        if main_fns
      fns.concat(hooks[:after])   if hooks && hooks[:after]
      
      #TODO add around hooks

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
          vars << { :position => position_counter, :var => segment.gsub(':', '') }
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
      h1[:before] ||= []
      h1[:after]  ||= []
      h2[:before] ||= []
      h2[:after]  ||= []

      # merge
      h1[:before].concat(h2[:before])
      h1[:after].concat(h2[:after])
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
        data[v[:var]] = Pakyow.app.request.url_parts[v[:position]]
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
