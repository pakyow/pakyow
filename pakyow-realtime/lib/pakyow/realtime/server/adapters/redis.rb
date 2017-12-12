# frozen_string_literal: true

require "redis"

module Pakyow
  module Realtime
    class Server
      module Adapter
        # Manages websocket channels in redis.
        #
        # Use this in production.
        #
        # @api private
        class Redis
          KEY_PART_SEPARATOR = "/"
          KEY_PREFIX = "realtime"
          INFINITY = "+inf"

          def initialize(server, config)
            @server = server
            @redis = ::Redis.new(url: config[:redis])
            @prefix = [config[:redis_prefix], KEY_PREFIX].join(KEY_PART_SEPARATOR)
          end

          def socket_subscribe(socket_id, channel)
            @redis.multi do |transaction|
              transaction.zadd(key_socket_ids_by_channel(channel), INFINITY, socket_id)
              transaction.zadd(key_channels_by_socket_id(socket_id), INFINITY, channel)
            end
          end

          def socket_unsubscribe(socket_id, channel)
            @redis.multi do |transaction|
              transaction.zrem(key_socket_ids_by_channel(channel), socket_id)
              transaction.zrem(key_channels_by_socket_id(socket_id), channel)
            end
          end

          def subscription_broadcast(channel, message)
            @server.transmit_message_to_connection_ids(message, socket_ids_for_channel(channel))
          end

          def expire(socket_id, seconds)
            time_expire = Time.now.to_i + seconds
            channels = channels_for_socket_id(socket_id)

            @redis.multi do |transaction|
              channels.each do |channel|
                transaction.zadd(key_socket_ids_by_channel(channel), time_expire, socket_id)
              end

              transaction.expireat(key_channels_by_socket_id(socket_id), time_expire + 1)
            end
          end

          def persist(socket_id)
            channels = channels_for_socket_id(socket_id)

            @redis.multi do |transaction|
              channels.each do |channel|
                transaction.zadd(key_socket_ids_by_channel(channel), INFINITY, socket_id)
              end

              transaction.persist(key_channels_by_socket_id(socket_id))
            end
          end

          protected

          def socket_ids_for_channel(channel)
            @redis.zrangebyscore(
              key_socket_ids_by_channel(channel), Time.now.to_i, INFINITY
            )
          end

          def channels_for_socket_id(socket_id)
            @redis.zrangebyscore(
              key_channels_by_socket_id(socket_id), Time.now.to_i, INFINITY
            )
          end

          def build_key(*parts)
            [@prefix].concat(parts).join(KEY_PART_SEPARATOR)
          end

          def key_socket_ids_by_channel(channel)
            build_key("channel:#{channel}")
          end

          def key_channels_by_socket_id(socket_id)
            build_key("socket_id:#{socket_id}")
          end
        end
      end
    end
  end
end
