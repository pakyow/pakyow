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

      def from_scope(route_eval, overrides = {})
				args = [:path, :fns, :hooks, :templates, :group].inject([]) do |acc, arg|
					acc << (overrides.fetch(arg) { route_eval.send(arg) })
				end

        instance = self.new(*args)
      end
    end

    def initialize(path = '/', fns = nil, hooks = nil, templates = nil, group = nil)
      @path      = path
      @fns       = fns || {}
      @routes    = HTTP_METHODS.inject({}) { |acc, m| acc[m] = []; acc }
      @hooks     = hooks || { before: [], after: [] }
      @templates = templates || {}
      @group     = group

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

    # Creates or retreives a named route function. When retrieving,
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
      name, hooks = self.class.parse_template_args(args)

      @templates[name] = [hooks, block]
    end

    def expand(t_name, g_name = nil, *args, &block)
      path, hooks = self.class.parse_expansion_args(args)
      path ||= ''

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
        # action(method, *args, &block)
      end
    end

    def template_defined?(template)
      !@templates[template].nil?
    end

    protected

		def build_route(method, *args, &block)
      path, name, fns, hooks = self.class.parse_route_args(args)

      fns ||= []
      # add passed block to fns
      fns << block if block_given?

      # merge route hooks with scoped hooks
      hooks = merge_hooks(hooks || {}, @hooks)

      # build the final list of fns
      fns = build_fns(fns, hooks)

      if path.is_a?(Regexp)
        regex = path
        vars  = []
      else
        # prepend scope path if we're in a scope
        path = File.join(@path, path)
        path = Utils::String.normalize_path(path)

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
    end
  end

  class RouteExpansionEval < RouteEval
    attr_writer :direct_path

    def eval(&block)
      @template_eval = RouteTemplateEval.from_scope(self, path: path, group: @group, hooks: @hooks)
			@template_eval.direct_path = @direct_path
			@template_eval.eval(&@template_block)

			@path = @template_eval.routes_path

      super
    end

    def set_template(expansion_name, template)
      @expansion_name = expansion_name
      @template_block = template[1]

      @hooks = merge_hooks(@hooks, template[0])
    end

    def action(method, *args, &block)
      fn, hooks = self.class.parse_action_args(args)
			fn = block if block_given?

			# get route info from template
			route = @template_eval.route_for_action(method)

			all_fns = route[3]
			all_fns[:fns].unshift(fn) if fn

			hooks = merge_hooks(hooks, all_fns[:hooks])
			route[3] = build_fns(all_fns[:fns], hooks)

			register_route(route)
    end

		def action_group(*args, &block)
      name, hooks = self.class.parse_action_group_args(args)
			group = @template_eval.group_named(name)

			hooks = merge_hooks(hooks, group[0])
			group(@expansion_name, hooks, &block)
		end

		def action_namespace(*args, &block)
      name, hooks = self.class.parse_action_namespace_args(args)
			namespace = @template_eval.namespace_named(name)

			hooks = merge_hooks(hooks, namespace[1])
			namespace(@expansion_name, namespace[0], hooks, &block)
		end

    def method_missing(method, *args, &block)
			if @template_eval.has_action?(method)
				action(method, *args, &block)
			elsif @template_eval.has_namespace?(method)
				action_namespace(method, *args, &block)
			elsif @template_eval.has_group?(method)
				action_group(method, *args, &block)
			else
				super
			end
		rescue NoMethodError
			raise UnknownTemplatePart, "No action, namespace, or group named '#{method}'"
    end

		def expand(*args, &block)
			args[2] = File.join(@template_eval.nested_path.gsub(@path, ''), args[2])
			super(*args, &block)
		end

		private

		class << self
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

      def parse_action_namespace_args(args)
        ret = []
        args.each { |arg|
          if arg.is_a?(Hash) # we have hooks
            ret[1] = arg
          elsif arg.is_a?(Symbol) # we have a name
            ret[0] = arg
          end
        }
        ret
      end

      def parse_action_group_args(args)
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

  class RouteTemplateEval < RouteEval
		attr_accessor :direct_path

		def initialize(*args)
			super

			@groups = {}
			@namespaces = {}

			@routes_path = path
			@nested_path = path
		end

		def has_action?(name)
		 	!route_for_action(name).nil?
		end

		def has_group?(name)
			!group_named(name).nil?
		end

		def has_namespace?(name)
			!namespace_named(name).nil?
		end

		def route_for_action(name)
			lookup.fetch(:grouped, {}).fetch(@group, {})[name]
		end

		def namespace_named(name)
			@namespaces[name]
		end

		def group_named(name)
			@groups[name]
		end

		def build_fns(fns, hooks)
			{
				fns: fns,
				hooks: hooks,
			}
		end

		def namespace(*args)
      path, name, hooks = self.class.parse_namespace_args(args)
			@namespaces[name] = [path, hooks]
		end

		def group(*args)
      name, hooks = self.class.parse_group_args(args)
			@groups[name] = [hooks]
		end

		def routes_path(&block)
			return @routes_path unless block_given?
			@routes_path = yield(@routes_path)
			@path = @routes_path
		end

		def nested_path(&block)
			return @nested_path unless block_given?
			@nested_path = yield(@nested_path)
		end
  end
end

