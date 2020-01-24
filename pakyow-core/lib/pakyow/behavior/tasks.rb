# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Tasks
      extend Support::Extension

      apply_extension do
        # Legacy task implementation follows, which is deprecated and will be removed in v2.0.
        #
        class_state :legacy_tasks, default: []
      end
    end
  end
end
