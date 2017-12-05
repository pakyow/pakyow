# frozen_string_literal: true

require "pakyow/core/routing/controller"
require "pakyow/core/routing/route"
require "pakyow/core/routing/extension"
require "pakyow/core/routing/route"
require "pakyow/core/routing/hook"
require "pakyow/core/routing/expansion"
require "pakyow/core/routing/extensions"

require "pakyow/core/framework"

module Pakyow
  module Routing
    class Framework < Pakyow::Framework(:routing)
      def boot
        controller_class = subclass(Controller) {
          include Pakyow::Routing::Extension::Resource
        }

        app.class_eval do
          # Register the controller subclass as an endpoint,
          # so that requests will potentially be handled.
          endpoint controller_class

          # Make it possible to define controllers on the app.
          stateful :controller, controller_class

          # Load defined controllers into the namespace.
          concern :controllers

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
          # Disabling the endpoint will work fine for now. Perhaps
          # some clarity on this issue can be found in the future.
          after :configure do
            if Pakyow.env?(:prototype)
              @endpoints.delete(controller_class)
            end
          end

          # Defines a RESTful resource.
          #
          # @see Routing::Extension::Resource
          #
          def self.resource(name, path, *args, &block)
            controller name, path, *args do
              expand_within(:resource, &block)
            end
          end

          # Registers an error handler automatically available in all Controller instances.
          #
          # @see Routing::Behavior::ErrorHandling#handle
          def self.handle(name_exception_or_code, as: nil, &block)
            const_get(:Controller).handle(name_exception_or_code, as: as, &block)
          end
        end
      end
    end
  end
end
