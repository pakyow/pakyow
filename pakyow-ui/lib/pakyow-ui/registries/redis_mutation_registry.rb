require 'json'

module Pakyow
  module UI
    # Manages mutations.
    #
    # This is the default registry in production systems and is required in
    # deployments with more than one app instance.
    #
    # @api private
    class RedisMutationRegistry
      include Singleton

      def initialize
      end

      def register(scope, mutation)
        Pakyow::Realtime.redis.sadd(key(scope), mutation.to_json)
      end

      def mutations(scope)
        Pakyow::Realtime.redis.smembers(key(scope)).map do |m|
          Hash.strhash(JSON.parse(m))
        end
      end

      private

      def key(scope)
        "pui-mutation-#{scope}"
      end
    end
  end
end
