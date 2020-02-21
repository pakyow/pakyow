# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Assets
    class Framework < Pakyow::Framework(:assets)
      def boot
        require "pakyow/application/behavior/assets"
        require "pakyow/application/behavior/assets/packs"
        require "pakyow/application/behavior/assets/silencing"
        require "pakyow/application/behavior/assets/externals"
        require "pakyow/application/behavior/assets/watching"
        require "pakyow/application/behavior/assets/prelaunching"
        require "pakyow/application/behavior/assets/processing"
        require "pakyow/application/behavior/assets/types"

        require "pakyow/presenter/renderer/behavior/assets/install_assets"

        require "pakyow/assets/asset"
        require "pakyow/assets/pack"

        require "pakyow/application/actions/assets/process"
        require "pakyow/application/actions/assets/public"

        object.class_eval do
          definable :asset_type, Asset

          # Let other frameworks load their own assets.
          #
          definable :asset, Asset

          # Let other frameworks load their own asset packs.
          #
          definable :pack, Pack

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

          include Application::Behavior::Assets
          include Application::Behavior::Assets::Packs
          include Application::Behavior::Assets::Silencing
          include Application::Behavior::Assets::Externals
          include Application::Behavior::Assets::Watching
          include Application::Behavior::Assets::Prelaunching
          include Application::Behavior::Assets::Processing
          include Application::Behavior::Assets::Types

          after "initialize" do
            action Application::Actions::Assets::Public, self
            action Application::Actions::Assets::Process
          end

          after "load" do
            isolated(:Renderer) do
              # Load this one later, in case other actions define components that will load assets.
              #
              include Presenter::Renderer::Behavior::Assets::InstallAssets
            end
          end
        end
      end
    end
  end
end
