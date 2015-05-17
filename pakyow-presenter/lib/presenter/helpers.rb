require 'forwardable'

module Pakyow
  module Helpers; end

  module AppHelpers
    extend Forwardable

    def_delegators :@presenter, :store, :store=, :content, :view=,
    :template=, :page=, :path, :path=, :compose, :composer, :precompose!

    def view
      ViewContext.new(@presenter.view, self)
    end

    def partial(*args)
      ViewContext.new(@presenter.partial(*args), self)
    end

    def template
      ViewContext.new(@presenter.template, self)
    end

    def page
      ViewContext.new(@presenter.page, self)
    end

    def container(*args)
      ViewContext.new(@presenter.container(*args), self)
    end

    def presenter
      @presenter
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end
  end
end
