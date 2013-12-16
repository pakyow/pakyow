module Pakyow
  module AppHelpers
    extend Forwardable

    def_delegators :@presenter, :store, :store=, :content, :view, :view=, 
    :partial, :template, :template=, :page, :page=, :path, :path=, :compose

    def presenter
      @presenter
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end
  end
end
