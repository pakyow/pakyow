require 'yaml'

require 'pakyow/presenter/view_store'
require 'pakyow/presenter/view'
require 'pakyow/presenter/form'
require 'pakyow/presenter/template'
require 'pakyow/presenter/page'
require 'pakyow/presenter/container'
require 'pakyow/presenter/partial'
require 'pakyow/presenter/view_collection'
require 'pakyow/presenter/binder'
require 'pakyow/presenter/binder_set'
require 'pakyow/presenter/attributes'
require 'pakyow/presenter/exceptions'
require 'pakyow/presenter/view_composer'
require 'pakyow/presenter/string_doc'
require 'pakyow/presenter/string_doc_parser'
require 'pakyow/presenter/string_doc_renderer'
require 'pakyow/presenter/binding_eval'
require 'pakyow/presenter/doc_helpers'
require 'pakyow/presenter/view_version'
require 'pakyow/presenter/view_context'
require 'pakyow/presenter/view_store_loader'

module Pakyow
  module Presenter
    def self.included(base)
      load_presenter(base)
    end

    def self.load_presenter(app_class)
      app_class.router :__presenter do
        handle 404 do
          presenter_handle_error(404)
        end

        handle 500 do
          presenter_handle_error(500)
        end
      end

      app_class.before :initialize do
        @presenter = Presenter.new(self)
        ViewStoreLoader.instance.reset
      end

      app_class.after :load do
        @presenter.load
      end
    end

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
