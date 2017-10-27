require 'pakyow/realtime/registries/simple_registry'
require 'pakyow/realtime/registries/redis_registry'

module Pakyow
  class App
    settings_for :realtime do
      setting :registry, Pakyow::Realtime::SimpleRegistry
      setting :redis, url: 'redis://127.0.0.1:6379'
      setting :redis_key, 'pw:channels'
      setting :enabled, true
      setting :delegate do
        Pakyow::Realtime::Delegate.new(config.realtime.registry.instance)
      end

      defaults :production do
        setting :registry, Pakyow::Realtime::RedisRegistry
      end
    end

    after :configure do
      # TODO: create the delegate
    end
  end
end
