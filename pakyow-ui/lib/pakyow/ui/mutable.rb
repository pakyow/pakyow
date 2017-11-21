# frozen_string_literal: true

require_relative "mutable_data"

# TODO: make it possible to register this as data instead of mutables

module Pakyow
  module UI
    # Mutables enable PakyowUI to automatically handle changes in application
    # state by interacting with the data layer in a declarative manner.
    #
    # Wraps a data source (such as a model object) and provides a convenient
    # interface for defining and executing queries and actions. Queries accept
    # parameters and return data sets. Actions cause a state change in
    # application state.
    #
    # Once defined, all interactions with the data layer should occur through
    # Mutables via the `data` helper method. When an action is performed that
    # changes the state of the application, Pakyow will propogate the change
    # through to all other connected clients automatically.
    #
    # Mutables should be registered with the `Pakyow::App.mutable` helper. The
    # defined block will be executed in context of a `Mutable` instance.
    #
    # @api public
    class Mutable
      include Helpers

      attr_reader :context

      # @api private
      def initialize(context, scope, &block)
        @context = context
        @scope   = scope
        @actions = {}
        @queries = {}

        instance_exec(&block)
      end

      # Sets the model object.
      #
      # @api public
      def model(model_class, type: nil)
        @model_class = model_class

        return if type.nil?
        @model_type = type

        # TODO: load default actions / queries based on type
      end

      # Defines an action.
      #
      # @api public
      def action(name, mutation: true, &block)
        @actions[name] = {
          block: block,
          mutation: mutation
        }
      end

      # Defines a query.
      #
      # @api public
      def query(name, &block)
        @queries[name] = block
      end

      # Handles calling queries or actions. Enables convenience like:
      #
      # data(:some_data).{action or query}
      #
      # @api public
      def method_missing(method, *args)
        action = @actions[method]
        query = @queries[method]

        if action
          call_action(action, *args)
        elsif query
          call_query(query, method, *args)
        else
          fail ArgumentError, "Could not find query or action named #{method}"
        end
      end

      private

      def call_action(action, *args)
        result = action[:block].call(*args)
        @context.ui.mutated(@scope, result, @context) if action[:mutation]
        result
      end

      def call_query(query, method, *args)
        MutableData.new(query, method, args, @scope)
      end
    end
  end
end
