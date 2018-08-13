# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          settings_for :presenter do
            setting :path do
              File.join(config.root, "frontend")
            end

            setting :embed_authenticity_token, true
          end
        end
      end
    end
  end
end
