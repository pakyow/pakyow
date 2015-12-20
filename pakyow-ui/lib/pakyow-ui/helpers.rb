module Pakyow
  module Helpers
    def ui
      context.ui
    end

    def data(scope)
      ui.mutator.mutable(scope, self)
    end

    module App
      attr_reader :ui
    end
  end
end
