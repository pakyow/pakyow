module Pakyow
  class RouteEval
    def initialize(path = '/', hooks = { :before => [], :after => []}, fns = {}, group_name = nil, namespace = false)
      @scope  = {:path => path, :hooks => hooks, :group_name => group_name, :namespace => namespace}
      @routes = {:get => [], :post => [], :put => [], :delete => []}
      @lookup = {:routes => {}, :grouped => {}}
      @fns  = fns
      @groups = {}
      @templates = {}
      @handlers = []

      self.eval(&RouteTemplateDefaults.defaults)
    end

    def eval(&block)
      self.instance_exec(&block)
    end

    def merge(routes, handlers, lookup)
      # routes.merge!(@routes)
      merge_routes(routes, @routes)
      handlers.concat(@handlers)
      # lookup.merge!(@lookup)

      merge_lookup(lookup, @lookup)

      return routes, handlers, lookup
    end

    # Creates or retreives a named route function. When retrieving, 
    #
    def fn(name, &block)
      @fns[name] = block and return if block
      @fns[name]
    end

    # def action(name, &block)
    #   @fns[name] = block and return if block
    #   @fns[name]
    # end

    def action(method, *args, &block)
      fn, hooks = self.class.parse_action_args(args)
      fns = block_given? ? [block] : [fn]
      @fns[method] = RouteEval.build_fns(fns, hooks)
    end

    def default(*args, &block)
      self.register_route(:get, '/', :default, *args, &block)
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
    
    # Creates a handler.
    #
    def handler(*args, &block)
      name, code, fn = self.class.parse_handler_args(args)
      fn = block if block_given?

      @handlers << [name, code, [fn]]
    end

    def group(*args, &block)
      name, hooks = self.class.parse_group_args(args)

      evaluator = RouteEval.new(@scope[:path], merge_hooks(hooks, @scope[:hooks]), @fns, name)
      evaluator.eval(&block)

      @routes, @handlers, @lookup = evaluator.merge(@routes, @handlers, @lookup)
    end

    def namespace(*args, &block)
      path, name, hooks = self.class.parse_namespace_args(args)

      #TODO shouldn't this be in parse_namespace_args?
      hooks = name if name.is_a?(Hash)

      evaluator = RouteEval.new(File.join(@scope[:path], path), merge_hooks(hooks, @scope[:hooks]), @fns, name, true)
      evaluator.eval(&block)

      @routes, @handlers, @lookup = evaluator.merge(@routes, @handlers, @lookup)
    end

    def template(*args, &block)
      name, hooks = self.class.parse_template_args(args)
      @templates[name] = [hooks, block]
    end

    def expand(t_name, g_name, *args, &block)
      path, hooks = self.class.parse_expansion_args(args)

      template = @templates[t_name]

      evaluator = RouteEval.new(File.join(@scope[:path], path), merge_hooks(merge_hooks(hooks, @scope[:hooks]), template[0]), @fns, g_name, true)
      evaluator.eval(&block)
      evaluator.eval(&template[1])

      @routes, @handlers, @lookup = evaluator.merge(@routes, @handlers, @lookup)
    end

    protected

    def merge_hooks(h1, h2)
      # normalize
      h1 = self.class.normalize_hooks(h1)
      h2 = self.class.normalize_hooks(h2)

      # merge
      h1[:before].concat(h2[:before])
      h1[:after].concat(h2[:after])
      h1[:around].concat(h2[:around])
      
      return h1
    end

    def merge_routes(r1, r2)
      r1[:get].concat(r2[:get])
      r1[:put].concat(r2[:put])
      r1[:post].concat(r2[:post])
      r1[:delete].concat(r2[:delete])

      return r1
    end

    def merge_lookup(l1, l2)
      l1[:routes].merge!(l2[:routes])
      l1[:grouped].merge!(l2[:grouped])

      return l1
    end

    def copy_hooks(hooks)
      {
        :before => (hooks[:before] || []).dup,
        :after => (hooks[:after] || []).dup,
        :around => (hooks[:around] || []).dup,
      }
    end

    def register_route(method, *args, &block)
      path, name, fns, hooks = self.class.parse_route_args(args)

      fns ||= []
      # add passed block to fns
      fns << block if block_given?

      # merge route hooks with scoped hooks
      hooks = self.merge_hooks(hooks || {}, @scope[:hooks])

      # build the final list of fns
      fns = self.class.build_fns(fns, hooks)

      if path.is_a?(Regexp)
        regex = path
        vars  = []
      else
        # prepend scope path if we're in a scope
        path = File.join(@scope[:path], path)
        path = StringUtils.normalize_path(path)
        
        # get regex and vars for path
        regex, vars = self.build_route_matcher(path)
      end

      # create the route tuple
      route = [regex, vars, name, fns, path]

      @routes[method] << route

      # add route to lookup, unless it's namespaced (because
      # then it can only be accessed through the grouping)
      unless namespace?
        @lookup[:routes][name] = route
      end

      # add to grouped lookup, if we're in a group
      if group?
        (@lookup[:grouped][@scope[:group_name]] ||= {})[name] = route
      end
    end

    def build_route_matcher(path)
      return path, [] if path.is_a?(Regexp)

      # check for vars
      return path, [] unless path[0,1] == ':' || path.index('/:')
      
      # we have vars
      vars = []
      regex_route = path
      route_segments = path.split('/')
      route_segments.each_with_index { |segment, i|
        if segment.include?(':')
          var = segment.gsub(':', '')
          vars << { :var => var.to_sym, :url_position => i }
          regex_route = regex_route.sub(segment, '(?<' + var + '>(\w|[-.~:@!$\'\(\)\*\+,;])*)')
        end
      }
      reg = Regexp.new("^#{regex_route}$")
      return reg, vars
    end

    def group?
      !@scope[:group_name].nil?
    end

    def namespace?
      @scope[:namespace]
    end

    class << self
      def parse_route_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[3] = arg
          elsif arg.is_a?(Array) # we have fns
            ret[2] = arg
          elsif arg.is_a?(Proc) # we have a fn
            ret[2] = [arg]
          elsif arg.is_a?(Symbol) # we have a name
            ret[1] = arg
          elsif !arg.nil? # we have a path
            ret[0] = arg
          end
        }
        ret
      end

      def parse_namespace_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[2] = arg
          elsif arg.is_a?(Symbol) # we have a name
            ret[1] = arg
          elsif !arg.nil? # we have a path
            ret[0] = arg
          end
        }
        ret
      end

      def parse_group_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[1] = arg
          elsif !arg.nil? # we have a name
            ret[0] = arg
          end
        }
        ret
      end

      def parse_handler_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Proc) # we have a fn
            ret[2] = arg
          elsif arg.is_a?(Integer) # we have a code
            ret[1] = arg
          elsif !arg.nil? # we have a name
            ret[0] = arg
          end
        }
        ret
      end

      def parse_template_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[1] = arg
          elsif !arg.nil? # we have a name
            ret[0] = arg
          end
        }
        ret
      end

      def parse_expansion_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[1] = arg
          elsif !arg.nil? # we have a path
            ret[0] = arg
          end
        }
        ret
      end

      def parse_action_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[1] = arg
          elsif arg.is_a?(Proc) # we have a fn
            ret[0] = arg
          end
        }
        ret
      end

      def build_fns(main_fns, hooks)
        hooks = self.normalize_hooks(hooks)
        fns = []
        fns.concat(hooks[:around])  if hooks && hooks[:around]
        fns.concat(hooks[:before])  if hooks && hooks[:before]
        fns.concat(main_fns)        if main_fns
        fns.concat(hooks[:after])   if hooks && hooks[:after]
        fns.concat(hooks[:around])  if hooks && hooks[:around]
        fns
      end

      def normalize_hooks(h)
        h ||= {}

        h[:before]  ||= []
        h[:after]   ||= []
        h[:around]  ||= []

        h[:before] = [h[:before]] unless h[:before].is_a?(Array)
        h[:after] = [h[:after]] unless h[:after].is_a?(Array)
        h[:around] = [h[:around]] unless h[:around].is_a?(Array)

        h
      end
    end
  end
end
