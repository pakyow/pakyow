require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "oga"
end

require "yaml"

require "pakyow/presenter/view"
require "pakyow/presenter/form"
require "pakyow/presenter/template"
require "pakyow/presenter/page"
require "pakyow/presenter/container"
require "pakyow/presenter/partial"
require "pakyow/presenter/view_collection"
require "pakyow/presenter/attributes"
require "pakyow/presenter/exceptions"
require "pakyow/presenter/string_doc"
require "pakyow/presenter/string_doc_parser"
require "pakyow/presenter/string_doc_renderer"
require "pakyow/presenter/doc_helpers"
require "pakyow/presenter/template_store"
require "pakyow/presenter/hooks"
require "pakyow/presenter/binder"

require "pakyow/presenter/presenter"
require "pakyow/presenter/config"
require "pakyow/presenter/state"

require "pakyow/extensions/controller"
require "pakyow/extensions/router"
