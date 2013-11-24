module Pakyow
  module RouteMerger
    private 

    def merge(route_eval)
      merge_fns(route_eval.fns)
      merge_routes(route_eval.routes)
      merge_handlers(route_eval.handlers)
      merge_lookup(route_eval.lookup)
      merge_templates(route_eval.templates)
    end

    def merge_fns(fns)
      @fns.merge!(fns)
    end

    def merge_routes(routes)
      @routes[:get].concat(routes[:get])
      @routes[:put].concat(routes[:put])
      @routes[:post].concat(routes[:post])
      @routes[:delete].concat(routes[:delete])
    end

    def merge_handlers(handlers)
      @handlers.concat(handlers)
    end

    def merge_lookup(lookup)
      @lookup[:routes].merge!(lookup[:routes])
      @lookup[:grouped].merge!(lookup[:grouped])
    end

    def merge_templates(templates)
      @templates.merge!(templates)
    end

    #TODO should this accept one or two args?
    def merge_hooks(h1, h2)
      # normalize
      h1 = normalize_hooks(h1)
      h2 = normalize_hooks(h2)

      # merge
      h1[:before].concat(h2[:before])
      h1[:after].concat(h2[:after])
      h1[:around].concat(h2[:around])

      return h1
    end

    def copy_hooks(hooks)
      {
        :before => (hooks[:before] || []).dup,
        :after => (hooks[:after] || []).dup,
        :around => (hooks[:around] || []).dup,
      }
    end

    def normalize_hooks(hooks)
      hooks ||= {}

      [:before, :after, :around].each do |type|
        # force array
        hooks[type] = Array(hooks[type])

        # lookup hook fns if not already a Proc
        hooks[type] = hooks[type].map do |hook|
          hook.is_a?(Symbol) ? fn(hook) : hook
        end
      end

      return hooks
    end
  end
end
