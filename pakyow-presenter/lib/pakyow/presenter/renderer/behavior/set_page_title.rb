# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module SetPageTitle
          extend Support::Extension

          apply_extension do
            attach do |presenter|
              presenter.render node: -> {
                if (title_value = info(:title))
                  title.object.set_label(:title_template, title_value)
                  title
                end
              } do
                self.html = html_safe(
                  Support::StringBuilder.new(object.label(:title_template), html_safe: true) { |object_value|
                    if respond_to?(object_value)
                      send(object_value, :title) || send(object_value)
                    elsif @presentables.key?(object_value)
                      @presentables[object_value]
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
end
