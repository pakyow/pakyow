# frozen_string_literal: true

require "pakyow/core/routing/controller"
require "pakyow/core/routing/route"
require "pakyow/core/routing/extension"
require "pakyow/core/routing/route"
require "pakyow/core/routing/hook"
require "pakyow/core/routing/expansion"
require "pakyow/core/routing/extensions"

module Pakyow
  module Routing
    def self.included(base)
      load_routing_into(base)
    end

    def self.load_routing_into(app_class)
      # TODO: this should happen automatically when loading the framework
      controller_subclass = Class.new(Controller)

      app_class.class_eval do
        # make the resource extension available in every controller
        controller_subclass.include Pakyow::Routing::Extension::Resource

        const_set(:Controller, controller_subclass)

        endpoint controller_subclass
        concern :controllers

        # @!scope class
        # @!method router(name_or_path = nil, path_or_name = nil, before: [], after: [], around: [], &block)
        #   Defines a router for the application. For example:
        #
        #     Pakyow::App.router do
        #     end
        #
        #   The router can be defined with a name, which creates a group
        #   (see {Router#group}). For example:
        #
        #     Pakyow::App.router :post do
        #     end
        #
        #   The router can also be created with both a name and path, which creates
        #   a namespace (see {Router#namespace}). For example:
        #
        #     Pakyow::App.router :post, "/posts" do
        #     end
        #
        #   It's possible to create an anonymous namespace by passing just a path.
        #   For example:
        #
        #     Pakyow::App.router "/posts" do
        #     end
        #
        #   Routes defined in the above router would be prefixed, but would be
        #   unavailable in path building (see {path} and {path_to}).
        #
        #   @param name_or_path [Symbol, String] the name or path for the router
        #   @param path_or_name [String, Symbol] the path or name for the router
        #   @param before [Array<Symbol, Proc>] an array of before hooks
        #   @param after [Array<Symbol, Proc>] an array of after hooks
        #   @param around [Array<Symbol, Proc>] an array of around hooks
        #
        stateful :controller, controller_subclass

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

Pakyow.register_framework :routing, Pakyow::Routing
