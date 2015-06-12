require_relative 'helpers'
require_relative 'ui'
require_relative 'mutator'
require_relative 'mutation_set'
require_relative 'mutable'
require_relative 'mutate_context'
require_relative 'ui_view'
require_relative 'channel_builder'
require_relative 'fetch_view_handler'
require_relative 'mutation_store'
require_relative 'registries/simple_mutation_registry'
require_relative 'registries/redis_mutation_registry'
require_relative 'config'
require_relative 'ui_component'

require_relative 'ext/app'
require_relative 'ext/app_context'
require_relative 'ext/view_context'

Pakyow::App.before :init do
  @ui = Pakyow::UI::UI.new
end

Pakyow::App.after :load do
  ui.load(mutators, mutables)
end

Pakyow::App.before :route do
  @context.ui = ui.dup
end
