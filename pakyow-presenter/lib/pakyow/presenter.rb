require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "oga"
end

require "pakyow/presenter/presenter"

require "pakyow/presenter/string_doc"
require "pakyow/presenter/string_node"
require "pakyow/presenter/string_attributes"
require "pakyow/presenter/significant"

require "pakyow/presenter/view"
require "pakyow/presenter/attributes"
require "pakyow/presenter/versioned_view"

require "pakyow/presenter/template_store"
require "pakyow/presenter/front_matter_parser"
require "pakyow/presenter/processor"
require "pakyow/presenter/binder"

require "pakyow/presenter/form"
require "pakyow/presenter/template"
require "pakyow/presenter/page"
require "pakyow/presenter/container"
require "pakyow/presenter/partial"

require "pakyow/presenter/presenters/form"
require "pakyow/presenter/presenters/view"

require "pakyow/extensions/app"
require "pakyow/extensions/controller"
require "pakyow/extensions/router"

require "pakyow/presenter/exceptions"
require "pakyow/presenter/helpers"
