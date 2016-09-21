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
    Pakyow::App.after :load do
      routes :__presenter do
        handler 404 do
          presenter_handle_error(404)
        end

        handler 500 do
          presenter_handle_error(500)
        end
      end
    end
  end
end
