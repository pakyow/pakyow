module Pakyow
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
    
    def post_process(&block)
      return @post_process unless block_given?
      @post_process = block
    end
  end
end
