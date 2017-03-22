require "forwardable"

module Pakyow
  module Routing
    # Expands a route template.
    #
    # @api private
    class Expansion
      using Support::DeepDup
      attr_reader :router, :name

      extend Forwardable
      def_delegators :@router, *[:func, :default, :group, :namespace, :template].concat(
        Router::SUPPORTED_METHODS.map { |method|
          method.downcase.to_sym
        }
      )

      def initialize(name, template, router)
        @name = name
        @router = router
        instance_eval(&template)
      end
      
      def route_exists?(name)
        return true if find_route(name)
      rescue NameError
        return false
      end

      def method_missing(name, *args, **hooks, &block)
        find_route(name).recompile(block: block, hooks: hooks)
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
