require 'forwardable'

module Pakyow
  module Helpers
    extend Forwardable

    def_delegators :@presenter, :store, :store=, :content, :view=,
    :template=, :page=, :path, :path=, :compose, :composer, :precompose!

    def view
      Presenter::ViewContext.new(presenter.view, self)
    end

    def partial(*args)
      Presenter::ViewContext.new(presenter.partial(*args), self)
    end

    def template
      Presenter::ViewContext.new(presenter.template, self)
    end

    def page
      Presenter::ViewContext.new(presenter.page, self)
    end

    def container(*args)
      Presenter::ViewContext.new(presenter.container(*args), self)
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end

    def presenter
      @presenter
    end
  end
end
