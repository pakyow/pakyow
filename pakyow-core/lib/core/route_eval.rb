module Pakyow
  class RouteEval
    include RouteMerger

    attr_reader :path, :fns, :routes, :handlers, :lookup, :templates

    def initialize(path = '/', hooks = { :before => [], :after => []}, fns = {}, group_name = nil, namespace = false)
      @path = path
      @scope  = {:path => path, :hooks => hooks, :group_name => group_name, :namespace => namespace}
      @routes = {:get => [], :post => [], :put => [], :delete => []}
      @lookup = {:routes => {}, :grouped => {}}
      @fns  = fns
      @groups = {}
      @templates = {}
      @handlers = []
    end

    def include(route_module)
      merge(route_module.route_eval)
    end

    def eval(template = false, &block)
      # if we're evaling a template, need to push
      # member routes to the end (they're always
      # created first, but need to be the last out)
      if template
        @member_routes = @routes
        @routes = {:get => [], :post => [], :put => [], :delete => []}
      end

      instance_exec(&block)

      if template
        merge_routes(@member_routes)
      end
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
      @fns[method] = build_fns(fns, hooks)
    end

    def default(*args, &block)
      register_route(:get, '/', :default, *args, &block)
    end

    def get(*args, &block)
      register_route(:get, *args, &block)
    end

    def put(*args, &block)
      register_route(:put, *args, &block)
    end

    def post(*args, &block)
      register_route(:post, *args, &block)
    end

    def delete(*args, &block)
      register_route(:delete, *args, &block)
    end

    # Creates a handler.
    #
    def handler(*args, &block)
      name, code, fns, hooks = self.class.parse_handler_args(args)
      fns ||= []
      # add passed block to fns
      fns << block if block_given?

      # build the final list of fns
      fns = build_fns(fns, hooks)

      @handlers << [name, code, fns]
    end

    def group(*args, &block)
      name, hooks = self.class.parse_group_args(args)

      evaluator = RouteEval.new(@scope[:path], merge_hooks(hooks, @scope[:hooks]), @fns, name)
      evaluator.eval(&block)
      merge(evaluator)
    end

    def namespace(*args, &block)
      path, name, hooks = self.class.parse_namespace_args(args)

      #TODO shouldn't this be in parse_namespace_args?
      hooks = name if name.is_a?(Hash)

      evaluator = RouteEval.new(File.join(@scope[:path], path), merge_hooks(hooks, @scope[:hooks]), @fns, name, true)
      evaluator.eval(&block)
      merge(evaluator)
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
      evaluator.eval(true, &template[1])
      merge(evaluator)
    end

    protected

    def register_route(method, *args, &block)
      path, name, fns, hooks = self.class.parse_route_args(args)

      fns ||= []
      # add passed block to fns
      fns << block if block_given?

      # merge route hooks with scoped hooks
      hooks = merge_hooks(hooks || {}, @scope[:hooks])

      # build the final list of fns
      fns = build_fns(fns, hooks)

      if path.is_a?(Regexp)
        regex = path
        vars  = []
      else
        # prepend scope path if we're in a scope
        path = File.join(@scope[:path], path)
        path = Utils::String.normalize_path(path)

        # get regex and vars for path
        regex, vars = build_route_matcher(path)
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

    # yields current path to the block for modification,
    # then updates paths for member routes
    def nested_path
      new_path = yield(@scope[:group_name], @path)

      # update paths of member routes
      @member_routes.each {|type,routes|
        routes.each { |route|
          path = Utils::String.normalize_path(File.join(new_path, route[4].gsub(/^#{Utils::String.normalize_path(@path)}/, '')))
          regex, vars = build_route_matcher(path)
          route[0] = regex
          route[1] = vars
          route[4] = path
        }
      }

      @path = new_path
    end

    def build_fns(main_fns, hooks)
      hooks = normalize_hooks(hooks)
      fns = []
      fns.concat(hooks[:around])  if hooks && hooks[:around]
      fns.concat(hooks[:before])  if hooks && hooks[:before]
      fns.concat(main_fns)        if main_fns
      fns.concat(hooks[:after])   if hooks && hooks[:after]
      fns.concat(hooks[:around])  if hooks && hooks[:around]
      fns
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
          if arg.is_a?(Hash) # we have hooks
            ret[3] = arg
          elsif arg.is_a?(Proc) # we have a fn
            ret[2] = [arg]
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
    end
  end
end
