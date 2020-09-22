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
      def_delegators :@expander, *%i[default template].concat(Controller::DEFINABLE_HTTP_METHODS)
      def_delegators :@controller, :action

      def initialize(template_name, controller, options, &template_block)
        @controller = controller

        # Create the controller that stores available routes, groups, and namespaces.
        #
        @expander = controller.make(nil, set_const: false)

        # Evaluate the template to define available routes, groups, and namespaces.
        #
        instance_exec(**options, &template_block)

        # Define helper methods for routes
        #
        local_expander = @expander
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
                  built_route = build_route(method, route.name, route.path || route.matcher, &block)

                  # Make sure the route was inserted in the same order as found in the template.
                  #
                  index_of_last_insert = local_expander.routes[method].index { |expander_route|
                    expander_route.name == @routes[method].last.name
                  }

                  insert_before_this_index = @routes[method].select { |each_route|
                    local_expander.routes[method].any? { |expander_route|
                      each_route.name == expander_route.name
                    }
                  }.map { |each_route|
                    local_expander.routes[method].index { |expander_route|
                      expander_route.name == each_route.name
                    }
                  }.find { |index|
                    index > index_of_last_insert
                  }

                  if insert_before_this_index
                    @routes[method].insert(
                      @routes[method].index { |each_route|
                        each_route.name == local_expander.routes[method][insert_before_this_index].name
                      }, @routes[method].delete_at(index_of_last_insert)
                    )
                  end

                  built_route
                end
              end
            end
          end
        end

        # Define helper methods for groups and namespaces
        #
        @expander.children.each do |child|
          unless @controller.singleton_class.instance_methods(false).include?(child.object_name.name)
            @controller.define_singleton_method child.object_name.name do |&block|
              if child.path.nil?
                group(child.object_name.name, &block)
              else
                namespace(child.object_name.name, child.path || child.matcher, &block)
              end
            end
          end
        end

        # Set the expansion on the controller.
        #
        @controller.expansions << template_name
      end

      def group(*args, **kwargs, &block)
        @expander.send(:group, *args, set_const: false, **kwargs, &block)
      end

      def namespace(*args, **kwargs, &block)
        @expander.send(:namespace, *args, set_const: false, **kwargs, &block)
      end
    end
  end
end
