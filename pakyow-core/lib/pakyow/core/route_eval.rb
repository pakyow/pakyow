module Pakyow
  class RouteEval
    include RouteMerger

    attr_reader :path, :fns, :hooks, :group, :routes, :handlers, :lookup, :templates

    HTTP_METHODS   = [:get, :post, :put, :patch, :delete]
    DEFAULT_MIXINS = ['Restful']

    class << self
      def with_defaults(*args)
        instance = self.new(*args)

        # Mixin defaults
        DEFAULT_MIXINS.each { |mixin| instance.include(Pakyow::Routes.const_get(mixin)) }

        return instance
      end

      def from_scope(route_eval, args = {})
				[:path, :fns, :hooks, :templates, :group].each do |arg|
          next unless value = route_eval.instance_variable_get(:"@#{arg}")
          args[arg] ||= value.dup
				end

        self.new(args)
      end
    end

    def initialize(path: '/', fns: {}, hooks: { before: [], after: [] }, templates: {}, group: nil)
      @path      = path
      @fns       = fns
      @hooks     = hooks
      @templates = templates
      @group     = group

      @routes    = HTTP_METHODS.inject({}) { |acc, m| acc[m] = []; acc }
      @lookup    = { routes: {}, grouped: {} }
      @handlers  = []
    end

    # Path for evals within this eval
    #
    def descendent_path
      @descendent_path || @path
    end

    def include(route_module)
      merge(route_module.route_eval)
    end

    def eval(&block)
      instance_exec(&block)
    end

    # Creates or retreives a named route function.
    #
    def fn(name, &block)
      if block_given?
        @fns[name] = block
      else
        @fns[name]
      end
    end

    # Creates a handler.
    #
    def handler(*args, &block)
      args = Aargv.normalize(args, name: Symbol, code: Integer, fn: Proc, hooks: Hash)

      fns = []
      # add the passed proc
      fns << args[:fn] unless args[:fn].nil?
      # add passed block to fns
      fns << block if block_given?

      # build the final list of fns
      fns = build_fns(fns, args[:hooks])

      @handlers.unshift([args[:name], args[:code], fns])
    end

    def group(*args, &block)
      name, hooks = self.class.parse_group_args(args)

      evaluator = RouteEval.from_scope(self, path: descendent_path, group: name, hooks: hooks)
      evaluator.eval(&block)

      merge(evaluator)
    end

    def namespace(*args, &block)
      path, name, hooks = self.class.parse_namespace_args(args)

      evaluator = RouteEval.from_scope(self, path: File.join(descendent_path, path), group: name, hooks: hooks)
      evaluator.eval(&block)

      merge(evaluator)
    end

    def template(*args, &block)
      args = Aargv.normalize(args, name: Symbol, hooks: Hash)
      @templates[args[:name]] = [args[:hooks], block]
    end

    def expand(t_name, g_name = nil, *args, &block)
      args = Aargv.normalize(args, path: [String, ''], hooks: Hash)
      path = args[:path]
      hooks = args[:hooks]
      template = @templates[t_name]

      evaluator = RouteExpansionEval.from_scope(self, path: File.join(descendent_path, path), group: g_name, hooks: hooks)
			evaluator.direct_path = path
      evaluator.set_template(g_name, template)
      evaluator.eval(&block)

      merge(evaluator)
    end

    def default(*args, &block)
      build_route(:get, '/', :default, *args, &block)
    end

    HTTP_METHODS.each do |method|
      define_method method do |*args, &block|
        build_route(method, *args, &block)
      end
    end

    # For the expansion of templates
    def method_missing(method, *args, &block)
      if template_defined?(method)
        expand(method, *args, &block)
      else
        super
      end
    end

    def template_defined?(template)
      !@templates[template].nil?
    end

    protected

		def build_route(method, *args, &block)
      args = Aargv.normalize(args, path: String, regex_path: Regexp, name: Symbol, fn: Proc, fns: Array, hooks: Hash)

      path = args[:path] || args[:regex_path]
      name = args[:name]

      fns = args[:fns] || []
      # add passed fn
      fns << args[:fn] unless args[:fn].nil?
      # add passed block to fns
      fns << block if block_given?

      # merge route hooks with scoped hooks
      hooks = merge_hooks(@hooks.dup, args[:hooks] || {})

      # build the final list of fns
      fns = build_fns(fns, hooks)

      if path.is_a?(Regexp)
        regex = path
        vars  = []
      else
        # prepend scope path if we're in a scope
        path = File.join(@path, path)
        path = String.normalize_path(path)

        # get regex and vars for path
        regex, vars = build_route_matcher(path)
      end

			register_route([regex, vars, name, fns, path, method])
		end

    def register_route(route)
      @routes[route[5]] << route

      if group?
        bucket = (@lookup[:grouped][@group] ||= {})
      else
        bucket = @lookup[:routes]
      end

			bucket[route[2]] = route
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
      !@group.nil?
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
    end
  end
end
