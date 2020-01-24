# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Tasks
      extend Support::Extension

      apply_extension do
        class_state :tasks, default: []
      end
    end
  end
end
