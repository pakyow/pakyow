module Pakyow
  module Data
    # Wraps a model instance, creating +Query+ objects for performed queries.
    #
    class ModelProxy
      def initialize(model)
        @model = model
      end

      def method_missing(method_name, *args)
        if query?(method_name)
          wrap :query, method_name, args do
            @model.send(method_name, *args)
          end
        elsif command?(method_name) || @model.respond_to?(method_name)
          @model.send(method_name, *args)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        query?(method_name) || command?(method_name) || @model.respond_to?(method_name) || super
      end

      protected

      def query?(maybe_query_name)
        @model.public_methods(false).include?(maybe_query_name)
      end

      def command?(maybe_command_name)
        @model.command?(maybe_command_name)
      end

      def wrap(type, name, args)
        Kernel.const_get("Pakyow::Data::#{type.to_s.capitalize}").new(yield, name, args)
      end
    end
  end
end
