# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module PresentPresentables
        extend Support::Extension

        apply_extension do
          attach do |presenter|
            presenter.render node: -> {
              binding_scopes.map { |node|
                View.from_object(node)
              }
            } do
              if presentable = @presentables[view.plural_channeled_binding_name] || @presentables[view.singular_channeled_binding_name] || @presentables[view.binding_name]
                present(presentable)
              end
            end
          end
        end
      end
    end
  end
end
