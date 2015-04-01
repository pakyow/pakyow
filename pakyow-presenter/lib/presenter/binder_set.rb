module Pakyow
  module Presenter
    class BinderSet
      attr_reader :scopes

      def initialize(&block)
        @scopes = {}
        @options = {}
        @config = {}

        instance_exec(&block)
      end

      def scope(name, &block)
        scope_eval = ScopeEval.new
        bindings, options, config = scope_eval.eval(&block)

        @scopes[name.to_sym] = bindings
        @options[name.to_sym] = options
        @config[name.to_sym] = config
      end

      def match_for_prop(prop, scope, bindable, bindings = {})
        return bindings_for_scope(scope, bindings)[prop]
      end

      def options_for_prop(scope, prop, bindable, context)
        if block = (@options[scope] || {})[prop]
          binding_eval = BindingEval.new(prop, bindable, context)
          values = binding_eval.instance_exec(binding_eval.value, bindable, context, &block)
          values.unshift(['', '']) if @config[scope][prop][:empty]
          values
        end
      end

      def has_prop?(scope, prop, bindings)
        bindings_for_scope(scope, bindings).key? prop
      end

      def bindings_for_scope(scope, bindings)
        # merge passed bindings with bindings
        (@scopes[scope] || {}).merge(bindings)
      end
    end

    class ScopeEval
      include Helpers

      def initialize
        @bindings = {}
        @options = {}
        @config = {}
      end

      def eval(&block)
        self.instance_eval(&block)
        return @bindings, @options, @config
      end

      def binding(name, &block)
        @bindings[name.to_sym] = block
      end

      def options(name, empty: false, &block)
        @options[name] = block
        @config[name] = { empty: empty }
      end

      def restful(route_group)
        binding :_root do
          routes = Router.instance.group(route_group)

          {
            view: lambda { |view|
              action = view.attrs.action.value
              return if (action && !action.empty?)

              route_params = params.dup
              if view.doc.tagname == 'form'
                if id = bindable[:id]
                  view.prepend(View.new('<input type="hidden" name="_method" value="patch">'))
                  route_params[:"#{route_group}_id"] = id
                  action = :update
                else
                  action = :create
                end

                view.attrs.action = routes.path(action, route_params)
                view.attrs.method = 'post'
              end
            }
          }
        end
      end
    end
  end
end
