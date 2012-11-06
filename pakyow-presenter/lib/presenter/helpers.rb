module Pakyow
  module Helpers
    def presenter
      Pakyow.app.presenter.current_context = self
      Pakyow.app.presenter
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end
    
    def view
      self.presenter.view
    end
  end
end
