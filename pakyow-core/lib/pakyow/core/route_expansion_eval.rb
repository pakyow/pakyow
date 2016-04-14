module Pakyow
  class RouteExpansionEval < RouteEval
    attr_writer :direct_path

    def eval(&block)
      @template_eval = RouteTemplateEval.from_scope(self, path: path, group: @group, hooks: @hooks)
  		@template_eval.direct_path = @direct_path
  		@template_eval.eval(&@template_block)
    
  		@path = @template_eval.routes_path

      super
      
      instance_exec(&@template_eval.post_process) if @template_eval.post_process
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

  		hooks = merge_hooks(all_fns[:hooks], hooks)
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
end
