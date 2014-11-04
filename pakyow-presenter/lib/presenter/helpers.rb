require 'forwardable'

module Pakyow
  module Helpers; end

  module AppHelpers
    extend Forwardable

    def_delegators :@presenter, :store, :store=, :content, :view=,
    :template=, :page=, :path, :path=, :compose, :composer

    def view
      ViewContext.new(@presenter.view, context)
    end

    def partial(*args)
      ViewContext.new(@presenter.partial(*args), context)
    end

    def template
      ViewContext.new(@presenter.template, context)
    end

    def page
      ViewContext.new(@presenter.page, context)
    end

    def container(*args)
      ViewContext.new(@presenter.container(*args), context)
    end

    def presenter
      @presenter
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end
  end
end
