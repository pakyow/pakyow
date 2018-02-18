# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Maintains a list of modules with helper methods used when fulfilling a request.
    #
    module Helpers
      extend Support::Extension

      apply_extension do
        config.app.setting :helpers, []
      end

      class_methods do
        # Registers a helper module to be loaded on defined endpoints.
        #
        def helper(helper_module)
          (config.app.helpers << helper_module).uniq!
        end
      end
    end
  end
end
