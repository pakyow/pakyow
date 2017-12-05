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
