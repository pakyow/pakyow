module Pakyow
  module Helpers
    def ui
      context.ui
    end

    def data(scope)
      ui.mutator.mutable(scope, context)
    end
  end
end
