# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Packs
        extend Support::Extension

        apply_extension do
          after :initialize do
            Pathname.glob(File.join(config.assets.frontend_asset_packs_path, "*.*")) do |asset_pack_path|
              if config.assets.extensions.include?(File.extname(asset_pack_path))
                asset_pack = Pack.new(File.basename(asset_pack_path, File.extname(asset_pack_path)).to_sym)
                asset_pack << Asset.new_from_path(asset_pack_path, config: config.assets)
                self.pack << asset_pack
              end
            end
          end
        end
      end
    end
  end
end
