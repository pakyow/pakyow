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
        Pakyow::Realtime.redis.sadd(key(scope: scope, socket_key: mutation[:socket_key]), mutation.to_json)
      end

      def mutations(scope)
        mutations = []

        keys(key(scope: scope)) do |key|
          Pakyow::Realtime.redis.smembers(key).each do |m|
            mutations << Hash.strhash(JSON.parse(m))
          end
        end

        mutations
      end

      def unregister(socket_key)
        keys(key(socket_key: socket_key)) do |key|
          Pakyow::Realtime.redis.del(key)
        end
      end

      private

      def key(scope: nil, socket_key: nil)
        if socket_key.nil?
          base = "*:"
        else
          base = "#{socket_key}:"
        end

        if scope.nil?
          "#{base}*"
        else
          "#{base}pui-mutation-#{scope}"
        end
      end

      def keys(match)
        cursor = 0

        loop do
          cursor, keys = Pakyow::Realtime.redis.scan(cursor, match: match)

          keys.each do |key|
            yield key
          end

          break if cursor == '0'
        end
      end
    end
  end
end
