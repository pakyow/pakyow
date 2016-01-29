module Pakyow
  class AppContext
    def ui
      return @ui unless @ui.nil?

      ui_dup = Pakyow.app.ui.dup
      ui_dup.context = self
      @ui = ui_dup
    end
  end
end
