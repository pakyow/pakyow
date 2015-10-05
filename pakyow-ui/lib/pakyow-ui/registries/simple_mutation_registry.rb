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

        return if @mutations[scope].include?(mutation)
        @mutations[scope] << mutation
      end

      def mutations(scope)
        @mutations[scope]
      end
    end
  end
end
