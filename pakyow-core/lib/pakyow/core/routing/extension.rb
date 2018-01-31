# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Routing
    # Makes it possible to define router extensions. For example:
    #
    #   module FooRoutes
    #     extend Pakyow::Routing::Extension
    #
    #     def foo
    #       # this method will be available to controllers that includes the extension
    #     end
    #
    #     apply_extension do
    #       get "/foo" do
    #         # this route will be defined on any controller that includes the extension
    #       end
    #     end
    #   end
    #
    #   Pakyow::App.router do
    #     include FooRoutes
    #   end
    #
    # See {Extension::Resource} for a more complex example.
    #
    module Extension
      def apply_extension(&block)
        @__extensions = block
      end

      def included(base)
        if base.ancestors.include?(Controller)
          base.instance_exec(&@__extensions) if @__extensions
        else
          raise StandardError, "Expected `#{base}' to be a subclass of `Pakyow::Controller'"
        end
      end
    end
  end
end
