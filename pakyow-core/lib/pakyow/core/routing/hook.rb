# frozen_string_literal: true

module Pakyow
  module Routing
    # @api private
    class Hook
      attr_reader :type

      def initialize(endpoint, type: nil, skip: nil)
        @endpoint, @type, @skip = endpoint, type, skip
      end

      def name
        if @endpoint.is_a?(Symbol)
          @endpoint
        else
          nil
        end
      end

      def call_in_context(context)
        if @endpoint.is_a?(Proc)
          context.instance_exec(&@endpoint)
        else
          context.public_send(@endpoint)
        end
      end

      def skip?(route, context)
        if @skip.is_a?(Array)
          @skip.include?(route.name)
        elsif @skip.is_a?(Proc)
          context.instance_exec(&@skip)
        end
      end
    end
  end
end
