# frozen_string_literal: true

module Pakyow
  module Data
    class Subscribers
      module Adapters
        class Redis
          # @api private
          class Pipeliner
            TIMEOUT = 1.0 / 100.0

            def initialize(redis)
              @redis = redis
              @commands = []
            end

            def enqueue(future)
              @commands << { future: future, callback: Proc.new }
            end

            def wait
              @commands.map { |command|
                while command[:future].value.is_a?(::Redis::FutureNotReady)
                  sleep TIMEOUT
                end

                command[:callback].call(command[:future].value)
              }
            end

            def self.pipeline(redis)
              pipeliner = Pipeliner.new(redis)

              redis.pipelined do
                yield pipeliner
              end

              pipeliner.wait
            end
          end
        end
      end
    end
  end
end
