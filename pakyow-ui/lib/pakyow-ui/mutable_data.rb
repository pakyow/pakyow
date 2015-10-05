module Pakyow
  module UI
    # Adds metadata to a dataset returned by a Mutable query.
    #
    # @api private
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
