require 'forwardable'

module Pakyow
  # Include in a module to define route mixins
  # that can be included into route sets.
  module Routes
    def self.included(base)
      raise StandardError, "Pakyow::Routes is intended to be included only in other modules" if base.is_a?(Class)

      base.extend(ClassMethods)
      base.instance_variable_set(:@route_eval, RouteEval.new)
    end

    module ClassMethods
      attr_reader :route_eval
      extend Forwardable
      def_delegators :@route_eval, :fn, :default, :get, :put, :post, :delete,
                     :handler, :group, :namespace, :template, :action, :expand
    end
  end
end
