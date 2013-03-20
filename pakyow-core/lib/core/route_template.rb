#TODO rename router to set and .func to .fn

module Pakyow
  class RouteTemplate
    attr_accessor :path

    def initialize(block, g_name, path, router)
      @fns    = {}
      @g_name = g_name
      @path   = path
      @router = router
      @nested_path = path
      @expansions = []

      self.instance_exec(&block)
    end

    def action(method, *args, &block)
      fns = block_given? ? [block] : args[0]
      @fns[method] = fns
    end

    def evaluate(template, data)
      @expanding = true

      t = self
      if @path
        @router.namespace(@path, @g_name) {
          t.instance_exec(data, &template)
        }
      else
        @router.group(@g_name) {
          t.instance_exec(data, &template)
        }
      end

      # expand nested expansions after initial expansion so
      # nested_path is guaranteed to be set
      @expansions.each {|c|
        # append nested path to nested expansion path
        c[1][2] = File.join(@nested_path, c[1][2])
        @router.send(c[0], *c[1], &c[2])
      }
    end

    def fn(name)
      if !@expanding || (@expanding && !fn = @fns[name])
        fn = @router.fn(name)
      end

      fn
    end

    def call(controller, action)
      @router.call(controller, action)
    end

    def default(*args, &block)
      @router.default(*args, &block)
    end

    def get(*args, &block)
      @router.get(*args, &block)
    end

    def put(*args, &block)
      @router.put(*args, &block)
    end

    def post(*args, &block)
      @router.post(*args, &block)
    end

    def delete(*args, &block)
      @router.delete(*args, &block)
    end

    def expand(*args, &block)
      @expansions << [:expand, args, block]
    end

    def group(*args, &block)
      args = args.unshift(@path)
      @router.namespace(*args, &block)
    end

    def namespace(*args, &block)
      path, name, hooks = RouteSet.parse_namespace_args(args)
      path = File.join(@path, path)
      @router.namespace(*[path, name, hooks], &block)
    end

    def nested_path
      @nested_path = yield(@g_name, @nested_path)
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

