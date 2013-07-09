module Pakyow
  module AppHelpers
    def presenter
      @presenter
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end

    def view
      presenter.view
    end
  end
end
