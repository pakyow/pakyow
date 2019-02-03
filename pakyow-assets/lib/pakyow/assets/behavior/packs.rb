# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Packs
        extend Support::Extension

        apply_extension do
          after :initialize do
            config.assets.packs.paths.each do |packs_path|
              Pathname.glob(File.join(packs_path, "*.*")).group_by { |path|
                File.join(File.dirname(path), File.basename(path, File.extname(path)))
              }.to_a.sort { |pack_a, pack_b|
                pack_b[1] <=> pack_a[1]
              }.uniq { |pack_path, _|
                accessible_pack_path(pack_path)
              }.map { |pack_path, pack_asset_paths|
                [accessible_pack_path(pack_path), pack_asset_paths]
              }.reverse.each do |pack_path, pack_asset_paths|
                prefix = if is_a?(Plugin)
                  self.class.mount_path
                else
                  "/"
                end

                asset_pack = Pack.new(File.basename(pack_path).to_sym, config.assets, prefix: prefix)

                pack_asset_paths.each do |pack_asset_path|
                  if config.assets.extensions.include?(File.extname(pack_asset_path))
                    asset_pack << Asset.new_from_path(
                      pack_asset_path,
                      config: config.assets,
                      related: state(:asset)
                    )
                  end
                end

                self.pack << asset_pack.finalize
              end
            end
          end
        end

        def accessible_pack_path(pack_path)
          pack_path_parts = pack_path.split("/")
          # pack_path.split("__", 2)[1].split("@", 2)[0]
          pack_path_parts[-1] = if pack_path_parts[-1].include?("__")
            pack_path_parts[-1].split("__", 2)[1]
          elsif pack_path_parts[-1].include?("@")
            pack_path_parts[-1].split("@", 2)[0]
          else
            pack_path_parts[-1]
          end

          pack_path_parts.join("/")
        end
      end
    end
  end
end
