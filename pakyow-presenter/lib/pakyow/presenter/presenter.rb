module Pakyow
  module Presenter
    def self.included(base)
      load_presenter_into(base)
    end

    def self.load_presenter_into(app_class)
      # TODO: automatically present 404/500
      # app_class.router :__presenter do
      #   handle 404 do
      #     presenter_handle_error(404)
      #   end

      #   handle 500 do
      #     presenter_handle_error(500)
      #   end
      # end

      app_class.after :configure do
        app_class.template_store << TemplateStore.new(:default, config.presenter.path)
      end
    end

    # protected

    # def presenter_handle_error(code)
    #   return if !config.app.errors_in_browser || req.format != :html
    #   response.body = [content_for_code(code)]
    # end

    # def content_for_code(code)
    #   content = ERB.new(File.read(path_for_code(code))).result(binding)
    #   page = Presenter::Page.new(:presenter, content, "/")
    #   composer = presenter.compose_at("/", page: page)
    #   composer.to_html
    # end

    # def path_for_code(code)
    #   File.join(
    #     File.expand_path("../../../", __FILE__),
    #     "views",
    #     "errors",
    #     code.to_s + ".erb"
    #   )
    # end
  end

  class Router
    def_delegators :controller, :render
  end

  class Controller
    def render(path = request.route_path || request.path)
      if composer = find_composer_for(path)
        yield composer if block_given?
        halt StringIO.new(composer.to_html)
      else
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
