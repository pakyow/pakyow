# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Presenter
      module Multiapp
        extend Support::Extension

        apply_extension do
          setting :common_frontend_path do
            File.join(config.common_path, "frontend")
          end
        end
      end
    end
  end
end
