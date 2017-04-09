module Pakyow
  module Presenter
    def self.included(base)
      load_presenter_into(base)
    end

    def self.load_presenter_into(app_class)
      app_class.after :configure do
        app_class.template_store << TemplateStore.new(:default, config.presenter.path)

        if environment == :development
          app_class.handle Pakyow::Presenter::MissingView, as: 500 do
            respond_to :html do
              render "/missing_view"
            end
          end

          app_class.template_store << TemplateStore.new(:errors, File.join(File.expand_path("../../", __FILE__), "views", "errors"))

          # TODO: define view objects to render built-in errors
        end

        app_class.handle 404 do
          respond_to :html do
            render "/404"
          end
        end

        app_class.handle 500 do
          respond_to :html do
            render "/500"
          end
        end
      end
    end
  end

  class Router
    def_delegators :controller, :render
  end

  class Controller
    def render(path = request.route_path || request.path)
      if composer = find_composer_for(path)
        yield composer if block_given?
        halt StringIO.new(composer.to_html)
      elsif found?
        raise Presenter::MissingView.new("No view at path `#{path}'")
      end
    end

    protected

    def find_composer_for(path)
      collapse_path(path) do |collapsed_path|
        if composer = composer_for_path(collapsed_path)
          return composer
        end
      end

      nil
    end

    def composer_for_path(path)
      app.state_for(:template_store).each do |store|
        begin
          return store.composer(path)
        # TODO: consider simply returning nil and only letting `render` raise this error
        rescue Presenter::MissingView
        end
      end

      nil
    end

    def collapse_path(path)
      yield path
      parts = path.split("/")
      parts.reverse.each do |part|
        next unless part[0] == ":"
        yield parts[0...parts.index(part)].join("/")
      end
    end
  end
end
