require_relative 'registries/simple_mutation_registry'
require_relative 'registries/redis_mutation_registry'

Pakyow::Config.register :ui do |config|
  # The registry to use when keeping up with connections.
  config.opt :registry, Pakyow::UI::SimpleMutationRegistry
end.env :development do |opts|
  opts.registry = Pakyow::UI::SimpleMutationRegistry
end.env :production do |opts|
  opts.registry = Pakyow::UI::RedisMutationRegistry
end
