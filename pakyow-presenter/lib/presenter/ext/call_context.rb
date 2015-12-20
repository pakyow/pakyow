module Pakyow
  class CallContext
    protected

    def presenter_handle_error(code)
      return if !config.app.errors_in_browser || req.format != :html
      response.body = [content_for_code(code)]
    end

    def content_for_code(code)
      content = ERB.new(File.read(path_for_code(code))).result(binding)
      page = Presenter::Page.new(:presenter, content, '/')
      composer = presenter.compose_at('/', page: page)
      composer.to_html
    end

    def path_for_code(code)
      File.join(
        File.expand_path('../../../', __FILE__),
        'views',
        'errors',
        code.to_s + '.erb'
      )
    end
  end
end
