# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Behavior
      module Silencing
        extend Support::Extension

        apply_extension do
          class_state :silencers, default: []
        end

        class_methods do
          def silence(&block)
            @silencers << block
          end
        end
      end
    end
  end
end
