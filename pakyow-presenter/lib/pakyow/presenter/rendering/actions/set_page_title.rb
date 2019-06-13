# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module SetPageTitle
        extend Support::Extension

        apply_extension do
          attach do |presenter|
            title_value = nil
            presenter.render node: -> {
              if title_value = info(:title)
                title
              end
            } do
              self.html = html_safe(
                Support::StringBuilder.new(title_value, html_safe: true) { |object_value|
                  if respond_to?(object_value)
                    send(object_value, :title) || send(object_value)
                  elsif @presentables.key?(object_value)
                    @presentables[object_value]
                  else
                    nil
                  end
                }.build
              )
            end
          end
        end
      end
    end
  end
end
