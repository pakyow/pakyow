# frozen_string_literal: true

module Pakyow
  module Data
    # Wraps a model instance, creating +Query+ objects for performed queries
    # and triggering mutations when commands are called.
    #
    class ModelProxy
      def initialize(model, subscriber_store)
        @model, @subscriber_store = model, subscriber_store
      end

      BUILT_IN_MODEL_QUERY_METHODS = %i[all by_id].freeze

      def method_missing(method_name, *args, &block)
        if query?(method_name)
          wrap :query, method_name, args do
            ModelProxy.new(@model.class.new(@model.send(method_name, *args)), @subscriber_store)
          end
        elsif command?(method_name)
          results = Array.ensure(@model.send(method_name, *args))

          changed_values = args[0]

          changed_ids = results.map { |result|
            result[:id]
          }

          @subscriber_store.did_mutate(@model.class.name, changed_values, changed_ids)
        elsif @model.respond_to?(method_name)
          @model.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        query?(method_name) || command?(method_name) || @model.respond_to?(method_name) || super
      end

      protected

      def query?(maybe_query_name)
        BUILT_IN_MODEL_QUERY_METHODS.include?(maybe_query_name) || @model.public_methods(false).include?(maybe_query_name)
      end

      def command?(maybe_command_name)
        @model.command?(maybe_command_name)
      end

      def wrap(type, name, args)
        Kernel.const_get("Pakyow::Data::#{type.to_s.capitalize}").new(yield, name, args, @subscriber_store)
      end
    end
  end
end
