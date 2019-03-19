# frozen_string_literal: true

require "cgi"

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Building
        extend Support::Extension

        apply_extension do
          before :initialize do
            isolated(:ViewBuilder).action :embed_websocket, after: :embed_authenticity do |state|
              if head = state.view.object.find_first_significant_node(:head)
                head.append("<meta name=\"pw-socket\" ui=\"socket\">")
              end
            end
          end
        end
      end
    end
  end
end
