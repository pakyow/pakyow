# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Routing
    # Expands a route template.
    #
    # @api private
    class Expansion
      attr_reader :expander, :controller, :name

      extend Forwardable
      def_delegators :@expander, *%i(default group namespace template).concat(Controller::DEFINABLE_HTTP_METHODS)
      def_delegators :@controller, :action

      def initialize(template_name, controller, options, &template_block)
        @controller = controller

        # Create the controller that stores available routes, groups, and namespaces.
        #
        @expander = Controller.make

        # Evaluate the template to define available routes, groups, and namespaces.
        #
        instance_exec(**options, &template_block)

        # Define helper methods for routes
        #
        @expander.routes.each do |method, routes|
          routes.each do |route|
            unless @controller.singleton_class.instance_methods(false).include?(route.name)
              @controller.define_singleton_method route.name do |*args, &block|
                # Handle template parts named `new` by determining if we're calling `new` to expand
                # part of a template, or if we're intending to create a new controller instance.
                #
                # If args are empty we can be sure that we're creating a route.
                #
                if args.any?
                  super(*args)
                else
                  build_route(
                    method,
                    route.name,
                    route.path || route.matcher,
                    &block
                  )
                end
              end
            end
          end
        end

        # Define helper methods for groups and namespaces
        #
        @expander.children.each do |child|
          unless @controller.singleton_class.instance_methods(false).include?(child.__object_name.name)
            @controller.define_singleton_method child.__object_name.name do |&block|
              if child.path.nil?
                group(child.__object_name.name, &block)
              else
                namespace(child.__object_name.name, child.path || child.matcher, &block)
              end
            end
          end
        end

        # Set the expansion on the controller.
        #
        @controller.expansions << template_name
      end
    end
  end
end
