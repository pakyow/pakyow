require 'forwardable'

module Pakyow
  module Helpers; end

  module AppHelpers
    extend Forwardable

    def_delegators :@presenter, :store, :store=, :content, :view=,
    :partial, :template, :template=, :page, :page=, :path, :path=, :compose,
    :composer, :container

    def view
      ViewContext.new(@presenter.view, context)
    end

    def presenter
      @presenter
    end

    def bindings(name)
      presenter.bindings(name).bindings
    end
  end
end
