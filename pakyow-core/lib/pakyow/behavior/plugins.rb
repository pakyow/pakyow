# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Plugins
      extend Support::Extension

      apply_extension do
        class_state :plugins, default: {}
      end

      class_methods do
        def register_plugin(plugin_name, plugin_module)
          @plugins[plugin_name] = plugin_module
        end
      end
    end
  end
end
