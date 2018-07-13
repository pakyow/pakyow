# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Packs
        extend Support::Extension

        apply_extension do
          after :initialize do
            config.assets.packs_paths.each do |packs_path|
              Pathname.glob(File.join(packs_path, "*.*")).group_by { |path|
                File.join(File.dirname(path), File.basename(path, File.extname(path)))
              }.each do |pack_path, pack_asset_paths|
                asset_pack = Pack.new(File.basename(pack_path).to_sym, config.assets)

                pack_asset_paths.each do |pack_asset_path|
                  if config.assets.extensions.include?(File.extname(pack_asset_path))
                    asset_pack << Asset.new_from_path(pack_asset_path, config: config.assets)
                  end
                end

                self.pack << asset_pack.finalize
              end
            end
          end
        end
      end
    end
  end
end
