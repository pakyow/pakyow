require_relative 'registries/simple_registry'
require_relative 'registries/redis_registry'

Pakyow::Config.register(:realtime) { |config|
  # The registry to use when keeping up with connections.
  config.opt :registry, Pakyow::Realtime::SimpleRegistry

  # The Redis config hash.
  config.opt :redis, url: 'redis://localhost:6379'

  # The key used to keep track of channels in Redis.
  config.opt :redis_key, 'pw:channels'
}.env(:development) { |opts|
  opts.registry = Pakyow::Realtime::SimpleRegistry
}.env(:staging) { |opts|
  opts.registry = Pakyow::Realtime::RedisRegistry
}.env(:production) { |opts|
  opts.registry = Pakyow::Realtime::RedisRegistry
}
