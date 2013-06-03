module Pakyow
  class RouteTemplate
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
    end

    attr_accessor :path

    def initialize(block, g_name, path, route_set)
      @fns    = {}
      @g_name = g_name
      @path   = path
      @route_set = route_set
      @nested_path = path
      @expansions = []

      self.instance_exec(&block)
    end

    def action(method, *args, &block)
      fn, hooks = self.class.parse_action_args(args)
      fns = block_given? ? [block] : [fn]
      @fns[method] = RouteSet.build_fns(fns, hooks)
    end

    def evaluate(template)
      @expanding = true
      hooks, block = template

      t = self
      if @path
        @route_set.namespace(@path, @g_name, hooks) {
          t.instance_exec(&block)
        }
      else
        @route_set.group(@g_name, hooks) {
          t.instance_exec(&block)
        }
      end

      # expand nested expansions after initial expansion so
      # nested_path is guaranteed to be set
      @expansions.each {|c|
        # append nested path to nested expansion path
        c[1][2] = File.join(@nested_path, c[1][2])
        @route_set.send(c[0], *c[1], &c[2])
      }
    end

    def fn(name)
      if !@expanding || (@expanding && !fn = @fns[name])
        fn = @route_set.fn(name)
      end

      fn
    end

    def call(controller, action)
      @route_set.call(controller, action)
    end

    def default(*args, &block)
      @route_set.default(*args, &block)
    end

    def get(*args, &block)
      @route_set.get(*args, &block)
    end

    def put(*args, &block)
      @route_set.put(*args, &block)
    end

    def post(*args, &block)
      @route_set.post(*args, &block)
    end

    def delete(*args, &block)
      @route_set.delete(*args, &block)
    end

    def expand(*args, &block)
      @expansions << [:expand, args, block]
    end

    def group(*args, &block)
      args = args.unshift(@path)
      @route_set.namespace(*args, &block)
    end

    def namespace(*args, &block)
      path, name, hooks = RouteSet.parse_namespace_args(args)
      path = File.join(@path, path)
      @route_set.namespace(*[path, name, hooks], &block)
    end

    def nested_path
      @nested_path = yield(@g_name, @nested_path)
    end

    def restful_actions
      [:index, :show, :new, :create, :edit, :update, :delete]
    end
  end
end

