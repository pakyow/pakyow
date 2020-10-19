# frozen_string_literal: true

require "redis"
require "concurrent/array"
require "concurrent/timer_task"
require "connection_pool"

require "pakyow/support/deep_freeze"

module Pakyow
  module Realtime
    class Server
      module Adapters
        # Manages websocket channels in redis.
        #
        # Use this in production.
        #
        # @api private
        class Redis
          KEY_PART_SEPARATOR = "/"
          KEY_PREFIX = "realtime"
          INFINITY = "+inf"

          PUBSUB_PREFIX = "pubsub"

          include Support::DeepFreeze
          insulate :redis

          def initialize(server, config)
            @server, @config = server, config
            @prefix = [@config[:key_prefix], KEY_PREFIX].join(KEY_PART_SEPARATOR)

            connect
            cleanup
          end

          def connect
            @redis = ConnectionPool.new(**@config[:pool]) {
              ::Redis.new(@config[:connection])
            }

            @buffer = Buffer.new(@redis, pubsub_channel)
            @subscriber = Subscriber.new(::Redis.new(@config[:connection]), pubsub_channel) { |payload|
              channel, message = Marshal.restore(payload).values_at(:channel, :message)
              @server.transmit_message_to_connection_ids(message, socket_ids_for_channel(channel), raw: true)
            }
          end

          def disconnect
            @subscriber.disconnect
          end

          def socket_subscribe(socket_id, *channels)
            @redis.with do |redis|
              redis.multi do |transaction|
                channels.each do |channel|
                  channel = channel.to_s
                  transaction.zadd(key_socket_ids_by_channel(channel), INFINITY, socket_id)
                  transaction.zadd(key_channels_by_socket_id(socket_id), INFINITY, channel)
                end
              end
            end
          end

          def socket_unsubscribe(*channels)
            @redis.with do |redis|
              channels.each do |channel|
                channel = channel.to_s

                # Channel could contain a wildcard, so this takes some work...
                redis.scan_each(match: key_socket_ids_by_channel(channel)) do |key|
                  channel = key.split("channel:", 2)[1]

                  socket_ids = redis.zrangebyscore(
                    key, Time.now.to_i, INFINITY
                  )

                  redis.multi do |transaction|
                    transaction.del(key)

                    socket_ids.each do |socket_id|
                      transaction.zrem(key_channels_by_socket_id(socket_id), channel)
                    end
                  end
                end
              end
            end
          end

          def subscription_broadcast(channel, message)
            @buffer << Marshal.dump(channel: channel, message: {payload: message}.to_json)
          end

          def expire(socket_id, seconds)
            time_expire = Time.now.to_i + seconds
            channels = channels_for_socket_id(socket_id)

            @redis.with do |redis|
              redis.multi do |transaction|
                channels.each do |channel|
                  transaction.zadd(key_socket_ids_by_channel(channel), time_expire, socket_id)
                end

                transaction.expireat(key_channels_by_socket_id(socket_id), time_expire + 1)
                transaction.expireat(key_socket_instance_id_by_socket_id(socket_id), time_expire + 1)
              end
            end
          end

          def persist(socket_id)
            channels = channels_for_socket_id(socket_id)

            @redis.with do |redis|
              redis.multi do |transaction|
                channels.each do |channel|
                  transaction.zadd(key_socket_ids_by_channel(channel), INFINITY, socket_id)
                end

                transaction.persist(key_channels_by_socket_id(socket_id))
                transaction.persist(key_socket_instance_id_by_socket_id(socket_id))
              end
            end
          end

          def current!(socket_id, socket_instance_id)
            @redis.with do |redis|
              redis.set(key_socket_instance_id_by_socket_id(socket_id), socket_instance_id)
            end
          end

          def current?(socket_id, socket_instance_id)
            @redis.with do |redis|
              redis.get(key_socket_instance_id_by_socket_id(socket_id)) == socket_instance_id.to_s
            end
          end

          protected

          def socket_ids_for_channel(channel)
            @redis.with do |redis|
              redis.zrangebyscore(
                key_socket_ids_by_channel(channel), INFINITY, INFINITY
              )
            end
          end

          def channels_for_socket_id(socket_id)
            @redis.with do |redis|
              redis.zrangebyscore(
                key_channels_by_socket_id(socket_id), INFINITY, INFINITY
              )
            end
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

          def key_socket_instance_id_by_socket_id(socket_id)
            build_key("socket_instance_id:#{socket_id}")
          end

          def pubsub_channel
            [@prefix, PUBSUB_PREFIX].join(KEY_PART_SEPARATOR)
          end

          def cleanup
            Concurrent::TimerTask.new(execution_interval: 300, timeout_interval: 300) {
              Pakyow.logger.internal do
                "[Pakyow::Realtime::Server::Adapters::Redis] Cleaning up channel keys"
              end

              removed_count = 0
              @redis.with do |redis|
                redis.scan_each(match: key_socket_ids_by_channel("*")) do |key|
                  socket_ids = redis.zrangebyscore(
                    key, Time.now.to_i, INFINITY
                  )

                  if socket_ids.empty?
                    removed_count += 1
                    redis.del(key)
                  end
                end
              end

              Pakyow.logger.internal {
                "[Pakyow::Realtime::Server::Adapters::Redis] Removed #{removed_count} keys"
              }
            }.execute
          end

          class Buffer
            # The number of publish commands to pipeline to redis.
            #
            PUBLISH_BUFFER_SIZE = 1_000

            # How often the publish buffer should be flushed.
            #
            PUBLISH_BUFFER_FLUSH_MS = 150

            include Support::DeepFreeze
            insulate :redis, :buffer

            def initialize(redis, channel)
              @redis, @channel = redis, channel
              @buffer = Concurrent::Array.new
            end

            def <<(payload)
              @buffer << payload
              maybe_flush
            end

            protected

            def maybe_flush
              if @buffer.count > PUBLISH_BUFFER_SIZE
                flush
              end

              unless @task&.pending?
                @task = Concurrent::ScheduledTask.execute(PUBLISH_BUFFER_FLUSH_MS / 1_000) {
                  flush
                }
              end
            end

            def flush
              @redis.with do |redis|
                redis.pipelined do |pipeline|
                  until @buffer.empty?
                    pipeline.publish(@channel, @buffer.shift)
                  end
                end
              end
            end
          end

          class Subscriber
            include Support::DeepFreeze
            insulate :redis

            def initialize(redis, channel, &callback)
              @redis, @channel, @callback = redis, channel, callback

              @thread = Thread.new {
                subscribe
              }
            end

            def disconnect
              @thread.exit
              @redis.disconnect!
            end

            def subscribe
              @redis.subscribe(@channel) do |on|
                on.message do |_, payload|
                  @callback.call(payload)
                rescue => error
                  Pakyow.logger.error "[Pakyow::Realtime::Server::Adapters::Redis] Subscriber callback failed: #{error}"
                end
              end
            rescue ::Redis::CannotConnectError
              Pakyow.logger.error "[Pakyow::Realtime::Server::Adapters::Redis] Subscriber disconnected"
              resubscribe
            rescue => error
              Pakyow.logger.error "[Pakyow::Realtime::Server::Adapters::Redis] Subscriber crashed: #{error}"
              resubscribe
            end

            def resubscribe
              sleep 0.25
              subscribe
            end
          end
        end
      end
    end
  end
end
