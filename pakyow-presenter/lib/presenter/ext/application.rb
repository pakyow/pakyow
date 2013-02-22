module Pakyow
  class Application
    def bindings(&block)
      Pakyow.app.presenter.instance_exec(&block)
    end

    def scope(name, set = :default, &block)
      Pakyow.app.presenter.scope(name, set, &block)
    end
  end
end
