# frozen_string_literal: true

require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "oga"
end

require "pakyow/presenter/framework"
require "pakyow/presenter/presenter"

require "pakyow/presenter/string_doc"
require "pakyow/presenter/string_node"
require "pakyow/presenter/string_attributes"
require "pakyow/presenter/significant_nodes"

require "pakyow/presenter/view"
require "pakyow/presenter/attributes"
require "pakyow/presenter/versioned_view"

require "pakyow/presenter/templates"
require "pakyow/presenter/front_matter_parser"
require "pakyow/presenter/processor"
require "pakyow/presenter/binder"
require "pakyow/presenter/binding_parts"

require "pakyow/presenter/views/form"
require "pakyow/presenter/views/layout"
require "pakyow/presenter/views/page"
require "pakyow/presenter/views/partial"

require "pakyow/presenter/presenters/form"

require "pakyow/presenter/errors"
require "pakyow/presenter/helpers"
