module Pakyow
  class App
    stateful :template_store, Presenter::TemplateStore
    stateful :view, Presenter::ViewPresenter
    stateful :binder, Presenter::Binder
    stateful :processor, Presenter::Processor

    settings_for :presenter do
      setting :path do
        File.join(config.app.root, "app", "presentation")
      end

      setting :require_route, true

      defaults :prototype do
        setting :require_route, false
      end
    end
  end
end
