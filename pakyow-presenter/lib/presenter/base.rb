require 'yaml'

require 'presenter/view_store'
require 'presenter/view'
require 'presenter/template'
require 'presenter/page'
require 'presenter/container'
require 'presenter/partial'
require 'presenter/view_collection'
require 'presenter/binder'
require 'presenter/binder_set'
require 'presenter/attributes'
require 'presenter/exceptions'
require 'presenter/view_composer'
require 'presenter/string_doc'
require 'presenter/string_doc_parser'
require 'presenter/string_doc_renderer'
require 'presenter/binding_eval'
require 'presenter/doc_helpers'
require 'presenter/view_version'
require 'presenter/view_context'
require 'presenter/view_store_loader'

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
