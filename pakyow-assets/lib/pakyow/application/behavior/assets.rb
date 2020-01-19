# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/assets/asset"

module Pakyow
  class Application
    module Behavior
      # Registers assets from the app's frontend/assets directory.
      #
      module Assets
        extend Support::Extension

        apply_extension do
          on "load", "load.assets" do
            config.assets.paths.each do |assets_path|
              Dir.glob(File.join(assets_path, "**/*")) do |path|
                next if config.assets.packs.paths.any? { |packs_path|
                  path.start_with?(packs_path)
                } || File.basename(path).start_with?("_")

                if config.assets.extensions.include?(File.extname(path))
                  assets << isolated(:Asset).new_from_path(
                    path,
                    config: config.assets,
                    source_location: assets_path,
                    related: assets
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
