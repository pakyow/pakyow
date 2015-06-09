require_relative 'registries/simple_mutation_registry'
require_relative 'registries/redis_mutation_registry'

Pakyow::Config.register(:ui) { |config|

  # The registry to use when keeping up with connections.
  config.opt :registry, Pakyow::UI::SimpleMutationRegistry

}.env(:development) { |opts|

  opts.registry = Pakyow::UI::SimpleMutationRegistry

}.env(:staging) { |opts|

  opts.registry = Pakyow::UI::RedisMutationRegistry

}.env(:production) { |opts|

  opts.registry = Pakyow::UI::RedisMutationRegistry

}
