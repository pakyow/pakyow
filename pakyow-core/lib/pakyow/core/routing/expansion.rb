require "forwardable"

module Pakyow
  module Routing
    class Expansion
      using Support::DeepDup
      attr_reader :router

      extend Forwardable
      def_delegators :@router, *[:func, :default, :group, :namespace, :template].concat(
        Router::SUPPORTED_METHODS.map { |method|
          method.downcase.to_sym
        }
      )

      def initialize(template, *args, &block)
        @template = template
        @router = Router.new(*args)
        instance_eval(&template)
        instance_eval(&block)
      end

      def method_missing(name, *args, **hooks, &block)
        route = find_route(name)
        route.recompile(block: block, hooks: hooks)
        # TODO: use a custom Routing::ExpansionError
      rescue NameError
        router.send(name, *args, **hooks, &block)
        # TODO: rescue again and reraise with a message about no template or part
      end

      def find_route(name)
        @router.routes.each do |method, routes|
          routes.each do |route|
            return route if route.name == name
          end
        end

        raise NameError, "Unknown template part `#{name}'"
      end

      def set_nested_path(nested_path)
        router.nested_path = nested_path
      end
    end
  end
end
