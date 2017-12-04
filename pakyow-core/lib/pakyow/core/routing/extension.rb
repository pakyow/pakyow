# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Routing
    # Makes it possible to define router extensions. For example:
    #
    #   module FooRoutes
    #     include Pakyow::Routing::Extension
    #
    #     get "/foo" do
    #       # this route will be defined on any router extended with FooRoutes
    #     end
    #   end
    #
    #   Pakyow::App.router do
    #     extend FooRoutes
    #   end
    #
    # See {Extension::Resource} for a more complex example.
    #
    module Extension
      # @api private
      def self.extended(base)
        base.instance_variable_set(:@__extension, Pakyow::Controller(nil))
        base.extend(ClassMethods)
      end

      # Methods available to the extension.
      #
      module ClassMethods
        extend Forwardable

        # @!method get
        #   @see Controller.get
        # @!method post
        #   @see Controller.post
        # @!method put
        #   @see Controller.put
        # @!method patch
        #   @see Controller.patch
        # @!method delete
        #   @see Controller.delete
        # @!method default
        #   @see Controller.default
        # @!method group
        #   @see Controller.group
        # @!method namespace
        #   @see Controller.namespace
        # @!method template
        #   @see Controller.template
        def_delegators :@__extension, *%i[default group namespace template].concat(Controller::SUPPORTED_HTTP_METHODS)

        # @api private
        def included(base)
          if base.ancestors.include?(Controller)
            base.merge(@__extension)
          else
            raise StandardError, "Expected `#{base}' to be a subclass of `Pakyow::Controller'"
          end
        end
      end
    end
  end
end
