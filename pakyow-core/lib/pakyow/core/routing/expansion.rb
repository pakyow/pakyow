# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Routing
    # Expands a route template.
    #
    # @api private
    class Expansion
      attr_reader :expander, :router, :name

      extend Forwardable
      def_delegators :expander, *%i[func default group namespace template].concat(Router::SUPPORTED_HTTP_METHODS)

      def initialize(template_name, router, &template_block)
        @router = router

        # Create the router that stores available routes, groups, and namespaces
        #
        @expander = Router.make(router.name, nil, **router.hooks)

        # Evaluate the template to define available routes, groups, and namespaces
        #
        instance_eval(&template_block)

        # Define helper methods for routes
        #
        @expander.routes.each do |method, routes|
          routes.each do |route|
            @router.define_singleton_method route.name do |*args, &block|
              if route.name == :new && args.first.is_a?(Controller) # handle template parts named `new`
                super(*args)
              else
                build_route(method, route.name, route.path || route.matcher, *args, &block)
              end
            end
          end
        end

        # Define helper methods for groups and namespaces
        #
        @expander.children.each do |child|
          @router.define_singleton_method child.name do |*args, &block|
            if child.path.nil?
              group(child.name, *args, &block)
            else
              namespace(child.name, child.path || child.matcher, *args, &block)
            end
          end
        end

        # Make the current template available to router we're adding to
        #
        @router.define_singleton_method :within do |*names, &block|
          super(*names) do
            expand_within(template_name, &block)
          end
        end
      end
    end
  end
end
