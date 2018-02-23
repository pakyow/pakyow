# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Behavior
      # Registers assets from the app's frontend/assets directory.
      #
      module Assets
        extend Support::Extension

        apply_extension do
          after :initialize do
            Dir.glob(File.join(config.assets.frontend_assets_path, "**/*")) do |path|
              next if path.start_with?(config.assets.frontend_asset_packs_path)
              next if File.basename(path).start_with?("_")

              if config.assets.extensions.include?(File.extname(path))
                self.asset << Asset.new_from_path(path, config: config.assets, source_location: config.assets.frontend_assets_path)
              end
            end
          end
        end
      end
    end
  end
end
