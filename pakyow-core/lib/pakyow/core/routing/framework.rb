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
    # @api private
    class RespondMissing
      def initialize(app)
        @app = app
      end

      def call(connection)
        @app.class.const_get(:Controller).new(connection).trigger(404)
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

          before :load do
            # Include other registered helpers into the controller class.
            config.app.helpers.each do |helper|
              controller_class.include helper
            end
          end

          before :freeze do
            unless Pakyow.env?(:prototype)
              state_for(:controller).each do |controller|
                @__pipeline.action(controller)
              end

              @__pipeline.action(RespondMissing, self)
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
