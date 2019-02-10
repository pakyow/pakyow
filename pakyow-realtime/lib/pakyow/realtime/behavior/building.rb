# frozen_string_literal: true

require "cgi"

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Building
        extend Support::Extension

        prepend_methods do
          def build_view(templates_path)
            super.tap do |view|
              if head = view.object.find_first_significant_node(:head)
                head.append(
                  <<~HTML
                    <meta name="pw-socket" ui="socket" config="{{pw-socket-config}}">
                  HTML
                )
              end
            end
          end
        end
      end
    end
  end
end
