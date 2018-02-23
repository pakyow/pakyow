# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          settings_for :assets do
            setting :types,
                    av: %w(.webm .snd .au .aiff .mp3 .mp2 .m2a .m3a .ogx .gg .oga .midi .mid .avi .wav .wave .mp4 .m4v .acc .m4a .flac),
                    data: %w(.json .xml .yml .yaml),
                    fonts: %w(.eot .otf .ttf .woff .woff2),
                    images: %w(.ico .bmp .gif .webp .png .jpg .jpeg .tiff .tif .svg),
                    scripts: %w(.js .es6 .eco .ejs),
                    styles: %w(.css .sass .scss)

            setting :extensions do
              config.assets.types.values.flatten
            end

            setting :public, true
            setting :cache, false
            setting :process, true
            setting :minify, false
            setting :fingerprint, false

            setting :public_path do
              File.join(config.root, "public")
            end

            setting :frontend_assets_path do
              File.join(config.presenter.path, "assets")
            end

            setting :frontend_asset_packs_path do
              File.join(config.presenter.path, "assets", "packs")
            end

            defaults :production do
              setting :minify, true
              setting :fingerprint, true
              setting :process, false
              setting :cache, true
            end
          end
        end
      end
    end
  end
end
