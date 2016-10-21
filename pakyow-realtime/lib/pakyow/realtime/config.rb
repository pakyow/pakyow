require_relative 'registries/simple_registry'
require_relative 'registries/redis_registry'

Pakyow::Config.register :realtime do |config|
  # The registry to use when keeping up with connections.
  config.opt :registry, Pakyow::Realtime::SimpleRegistry

  # The Redis config hash.
  config.opt :redis, url: 'redis://127.0.0.1:6379'

  # The key used to keep track of channels in Redis.
  config.opt :redis_key, 'pw:channels'

  # Whether or not realtime should be enabled.
  config.opt :enabled, true
end.env :production do |opts|
  opts.registry = Pakyow::Realtime::RedisRegistry
end
