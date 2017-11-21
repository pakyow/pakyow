# frozen_string_literal: true

module Pakyow
  class App
    stateful :template_store, Presenter::TemplateStore
    stateful :view, Presenter::ViewPresenter
    stateful :binder, Presenter::Binder
    stateful :processor, Presenter::Processor

    settings_for :presenter do
      setting :path do
        File.join(config.app.root, "interface")
      end

      setting :require_route, false
    end

    concern :views
    concern :binders
  end
end
