# frozen_string_literal: true

module Pakyow
  module UI
    # Manages mutations.
    #
    # Intended only for use in development or single app-instance deployments.
    #
    # @api private
    class SimpleMutationRegistry
      include Singleton

      def initialize
        reset
      end

      def reset
        @mutations = {}
      end

      def register(scope, mutation)
        @mutations[scope] ||= []
        @mutations[scope] << mutation
      end

      def unregister(socket_key)
        @mutations.each do |_, mutations|
          mutations.delete_if { |mutation|
            mutation[:socket_key] == socket_key
          }
        end
      end

      def mutations(scope)
        @mutations[scope]
      end
    end
  end
end
