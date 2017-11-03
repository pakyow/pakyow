require "pakyow/presenter/presentable"

module Pakyow
  class Router
    prepend Presenter::Presentable
    extend Presenter::Presentable::ClassMethods

    def_delegators :controller, :render
  end
end
