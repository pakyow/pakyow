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
      def_delegators :expander, *%i[default group namespace template].concat(Controller::SUPPORTED_HTTP_METHODS)

      def initialize(_template_name, controller, &template_block)
        @controller = controller

        # Create the controller that stores available routes, groups, and namespaces
        #
        @expander = Controller.make(controller.name, nil, **controller.hooks)

        # Evaluate the template to define available routes, groups, and namespaces
        #
        instance_eval(&template_block)

        # Define helper methods for routes
        #
        @expander.routes.each do |method, routes|
          routes.each do |route|
            @controller.define_singleton_method route.name do |*args, &block|
              # Handle template parts named `new` by determining if we're calling `new` to expand
              # part of a template, or if we're intending to create a new controller instance.
              #
              # It works by checking to see if the first argument is a call state object, which is
              # the first argument to Controller.new. If so, we can be reasonably sure that we want
              # to create a new controller. Yes, it's a bit of a hack. PRs welcome!
              if route.name == :new && args.first.is_a?(Pakyow::Call)
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
          @controller.define_singleton_method child.__class_name.name do |*args, &block|
            if child.path.nil?
              group(child.__class_name.name, *args, &block)
            else
              namespace(child.__class_name.name, child.path || child.matcher, *args, &block)
            end
          end
        end
      end
    end
  end
end
