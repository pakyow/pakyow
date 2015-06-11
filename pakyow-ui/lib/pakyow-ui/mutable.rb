#TODO consider moving this to a new pakyow-data library

module Pakyow
  module UI
    class Mutable
      def initialize(context, scope, &block)
        @context = context
        @scope   = scope
        @actions = {}
        @queries = {}

        instance_exec(&block)
      end

      def model(model_class, type: nil)
        @model_class = model_class

        if !type.nil?
          @model_type = type
          #TODO load default actions / queries based on type
        end
      end

      def action(name, mutation: true, &block)
        @actions[name] = {
          block: block,
          mutation: true,
        }
      end

      def query(name, &block)
        @queries[name] = block
      end

      def method_missing(method, *args)
        if action = @actions[method]
          result = action[:block].call(*args)
          if action[:mutation]
            @context.ui.mutated(@scope)
          end
          result
        elsif query = @queries[method]
          MutableData.new(query, method, args, @scope)
        else
          raise ArgumentError, "Could not find query or action named #{method}"
        end
      end
    end

    class MutableData
      attr_reader :query_name, :query_args, :scope

      def initialize(query, query_name, query_args, scope)
        @query = query
        @query_name = query_name
        @query_args = query_args
        @scope = scope
      end

      def data
        @data ||= @query.call(*@query_args)
      end
    end
  end
end
