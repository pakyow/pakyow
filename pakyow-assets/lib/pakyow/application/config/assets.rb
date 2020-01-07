# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/path_version"

module Pakyow
  class Application
    module Config
      module Assets
        extend Support::Extension

        apply_extension do
          configurable :assets do
            setting :types,
                    av: %w(.webm .snd .au .aiff .mp3 .mp2 .m2a .m3a .ogx .gg .oga .midi .mid .avi .wav .wave .mp4 .m4v .acc .m4a .flac),
                    data: %w(.json .xml .yml .yaml),
                    fonts: %w(.eot .otf .ttf .woff .woff2),
                    images: %w(.ico .bmp .gif .webp .png .jpg .jpeg .tiff .tif .svg),
                    scripts: %w(.js),
                    styles: %w(.css .sass .scss)

            setting :extensions do
              config.assets.types.values.flatten
            end

            setting :public, true
            setting :process, true
            setting :cache, false
            setting :minify, false
            setting :fingerprint, false
            setting :prefix, "/assets"
            setting :host, ""
            setting :silent, true
            setting :source_maps, true

            setting :public_path do
              File.join(config.root, "public")
            end

            setting :path do
              File.join(config.presenter.path, "assets")
            end

            setting :paths do
              [
                config.assets.path
              ]
            end

            setting :compile_path do
              case self
              when Plugin
                File.join(top.config.assets.public_path, mount_path)
              else
                config.assets.public_path
              end
            end

            setting :version do
              Support::PathVersion.build(config.assets.path, config.assets.public_path)
            end

            defaults :production do
              setting :minify, true
              setting :fingerprint, true
              setting :process, false
              setting :cache, true
              setting :silent, false
            end

            configurable :packs do
              setting :autoload, %i[pakyow]

              setting :path do
                File.join(config.assets.path, "packs")
              end

              setting :paths do
                [
                  config.assets.packs.path,
                  config.assets.externals.path
                ]
              end

              defaults :development, :prototype do
                setting :autoload, %i[pakyow devtools]
              end
            end

            configurable :externals do
              setting :fetch, true
              setting :pakyow, true
              setting :provider, "https://unpkg.com/"
              setting :scripts, []

              setting :path do
                File.join(config.assets.packs.path, "vendor")
              end

              defaults :test do
                setting :fetch, false
              end

              defaults :production do
                setting :fetch, false
              end
            end

            configurable :babel do
              setting :presets, ["es2015"]

              setting :source_maps do
                config.assets.source_maps
              end
            end

            configurable :uglifier do
              configurable :source_map do
                setting :sources_content, true
              end
            end

            configurable :sass do
              setting :cache, false
              setting :omit_source_map_url, true
              setting :source_map_contents, true

              setting :load_paths do
                [
                  config.assets.path
                ]
              end

              setting :style do
                if config.assets.minify
                  :compressed
                else
                  :nested
                end
              end
            end
          end
        end
      end
    end
  end
end
