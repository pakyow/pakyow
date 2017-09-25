module Pakyow
  class App
    stateful :template_store, Presenter::TemplateStore
    stateful :view, Presenter::ViewPresenter
    stateful :binder, Presenter::Binder

    settings_for :presenter do
      setting :path do
        File.join(config.app.root, "app", "presentation")
      end

      setting :require_route, true

      defaults :prototype do
        setting :require_route, false
      end
    end

    class << self
      # TODO: definable
      def processor(*args, &block)
        args.each {|format|
          processors[format] = block
        }
      end

      # TODO: definable
      def processors
        @processors ||= {}
      end
    end

    def processors
      self.class.processors
    end
  end
end
