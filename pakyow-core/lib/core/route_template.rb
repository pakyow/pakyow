#TODO rename router to set and .func to .fn

module Pakyow
  class RouteTemplate
    attr_accessor :path

    def initialize(block, g_name, path, router)
      @fns    = {}
      @g_name = g_name
      @path   = path
      @router = router

      self.instance_exec(&block)
    end

    def action(method, *args, &block)
      fns = block_given? ? [block] : args[0]
      @fns[method] = fns
    end

    def expand(template, data)
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
    end

    def fn(name)
      @expanding ? @fns[name] : @router.func(name)
    end

    def call(controller, action)
      @router.call(controller, action)
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

