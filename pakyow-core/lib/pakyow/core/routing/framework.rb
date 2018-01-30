# frozen_string_literal: true

require "pakyow/core/routing/controller"
require "pakyow/core/routing/route"
require "pakyow/core/routing/extension"
require "pakyow/core/routing/route"
require "pakyow/core/routing/expansion"
require "pakyow/core/routing/extensions"

require "pakyow/core/framework"

module Pakyow
  module Routing
    class Router
      class << self
        def call(state)
          state.app.state_for(:controller).each do |controller|
            catch :halt do
              controller.try_routing(state)
            end

            break if state.processed?
          end
        end
      end
    end

    class RespondToMissing
      class << self
        def call(state)
          catch :halt do
            state.app.class.const_get(:Controller).new(state).trigger(404)
          end
        end
      end
    end

    class RespondToFailure
      class << self
        def call(state)
          catch :halt do
            controller = state.app.class.const_get(:Controller).new(state)
            # try to handle the specific error
            controller.handle_error(state.request.error)
            # otherwise, just handle as a generic 500
            controller.trigger(500)
          end
        end
      end
    end

    # Defines a RESTful resource.
    #
    # @see Routing::Extension::Resource
    #
    def resource(name, path, *args, &block)
      controller name, path, *args do
        expand_within(:resource, &block)
      end
    end

    # Registers an error handler automatically available in all Controller instances.
    #
    # @see Routing::Behavior::ErrorHandling#handle
    def handle(name_exception_or_code, as: nil, &block)
      const_get(:Controller).handle(name_exception_or_code, as: as, &block)
    end

    # Extends an existing controller.
    #
    # @example
    #   controller :admin, "/admin" do
    #     before :require_admin
    #
    #     def require_admin
    #       ...
    #     end
    #   end
    #
    #   extend_controller :admin do
    #     resource :post, "/posts" do
    #       ...
    #     end
    #   end
    #
    def extend_controller(controller_name)
      if controller_name.is_a?(Support::ClassName)
        controller_name = controller_name.name
      end

      matched_controller = @state[:controller].instances.find { |controller|
        controller.__class_name.name == controller_name
      }

      if matched_controller
        matched_controller.instance_exec(&Proc.new)
      else
        fail "could not find controller named `#{controller_name}'"
      end
    end

    class Framework < Pakyow::Framework(:routing)
      def boot
        controller_class = subclass(Controller) {
          include Pakyow::Routing::Extension::Resource
        }

        app.class_eval do
          extend Routing

          # Make it possible to define controllers on the app.
          stateful :controller, controller_class

          # Load defined controllers into the namespace.
          aspect :controllers

          helper Pakyow::Routing::Helpers

          action Router
          action RespondToMissing, pipeline: :missing
          action RespondToFailure, pipeline: :failure

          # Remove the routing framework in prototype mode.
          #
          # Conditionally loading the routing framework based on
          # the environment was explored, but not feasible with
          # how things currently work. We don't know the env until
          # the environment is booted, but also include the framework
          # at definition time (which occurs well ahead of boot).
          #
          # Why? To support this:
          #
          #   Pakyow.app :some_app do
          #     controller do
          #       ...
          #     end
          #   end
          #
          # We'd either have to wait until boot time to build the
          # app object, or not allow defining app state inline. If
          # we wait, we introduce some misdirection because it is
          # no longer clear when the defined app will be built.
          #
          # Conditionally removing the action will work fine.
          after :configure do
            if Pakyow.env?(:prototype)
              config.app.pipelines[:routing].delete(Router)
            end
          end

          before :load do
            # Include other registered helpers into the controller class.
            config.app.helpers.each do |helper|
              controller_class.include helper
            end
          end
        end
      end
    end
  end

  class App
    # @!parse include Routing
  end
end
