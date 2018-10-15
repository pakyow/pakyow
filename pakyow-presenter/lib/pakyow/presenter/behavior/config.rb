# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          configurable :presenter do
            setting :path do
              File.join(config.root, "frontend")
            end

            setting :embed_authenticity_token, true

            configurable :ui do
              setting :navigable, true
            end
          end
        end
      end
    end
  end
end
