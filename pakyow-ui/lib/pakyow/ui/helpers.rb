module Pakyow
  module Helpers
    def ui
      return @ui unless !defined?(@ui) || @ui.nil?

      ui_dup = Pakyow.app.ui.dup
      ui_dup.context = self
      @ui = ui_dup
    end

    def data(scope)
      ui.mutator.mutable(scope, self)
    end
  end
end
