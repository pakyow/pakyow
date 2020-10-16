# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Assets
      module Multiapp
        extend Support::Extension

        apply_extension do
          setting :common_assets_path do
            File.join(config.common_frontend_path, "assets")
          end

          setting :common_asset_packs_path do
            File.join(config.common_assets_path, "packs")
          end
        end
      end
    end
  end
end
