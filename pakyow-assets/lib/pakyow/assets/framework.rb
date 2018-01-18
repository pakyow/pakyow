# frozen_string_literal: true

require "rack/proxy"

require "pakyow/assets/middleware/static"

require "pakyow/assets/process"

module Pakyow
  module Assets
    class Framework < Pakyow::Framework(:assets)
      def boot
        Pakyow.config.tasks.paths << File.expand_path("../tasks", __FILE__)

        app.class_eval do
          after :configure do
            builder.use Static

            # TODO: future feature
            # builder.map "/assets" do
            #   use Middleware::Proxy
            # end

            # We don't want pakyow to restart the server when an asset changes, since assets handles that itself.
            #
            Pakyow.config.server.ignore.concat([
              /#{File.expand_path(config.assets.local_public_asset_path).gsub(File.join(File.expand_path(config.app.root), "/"), "")}/,
              /#{File.expand_path(config.assets.frontend_assets_path).gsub(File.join(File.expand_path(config.app.root), "/"), "")}/,
              /#{File.expand_path(config.presenter.path).gsub(File.join(File.expand_path(config.app.root), "/"), "")}\/.*(#{config.assets.extensions.join("|")})/
            ])
          end

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

            setting :packs, {}
            setting :autoload, [:application]
            setting :polyfills, true
            setting :common, true
            setting :manifest, {}
            setting :manifest_hot_load, false
            setting :browsers, "last 2 versions"
            setting :source_maps, false
            setting :uglify, false
            setting :compress, false
            setting :fingerprint, false
            setting :config_file do
              File.join(config.app.root, "config/assets/environment.js")
            end

            setting :public_path, "/compiled/"

            setting :frontend_assets_path do
              File.join(config.presenter.path, "assets")
            end

            setting :local_public_path do
              File.join(config.app.root, "public")
            end

            setting :local_public_asset_path do
              File.join(config.assets.local_public_path, "compiled")
            end

            setting :output_path do
              config.assets.local_public_asset_path
            end

            setting :manifest_path do
              File.join(config.assets.output_path, "manifest.json")
            end

            defaults :development do
              setting :manifest_hot_load, true
              setting :source_maps, true
            end

            defaults :production do
              setting :uglify, true
              setting :compress, true
              setting :fingerprint, true
            end
          end

          after :freeze do
            build_packs

            config.assets.manifest = load_manifest

            if Pakyow.process
              process = Class.new(Pakyow::Assets::Process)
              process.watch(config.presenter.path)

              Pakyow.process.start_instance(process.new(Pakyow.process, self))
            end
          end

          def load_manifest
            if File.exists?(config.assets.manifest_path)
              JSON.parse(File.read(config.assets.manifest_path))
            else
              {}
            end
          end

          def build_packs
            config.assets.packs[:packs] = {}

            Dir.glob(File.join(config.assets.frontend_assets_path, "packs/*.js")) do |path|
              pack_name = File.basename(path, File.extname(path)).to_sym
              config.assets.packs[:packs][pack_name] = path
            end

            build_assets_pack

            if defined?(Presenter)
              build_frontend_pack
            end
          end

          def build_assets_pack
            config.assets.packs[:packs][:assets] = []

            Dir.glob(File.join(File.join(config.assets.frontend_assets_path, "**/*"))) do |path|
              next if path.start_with?(File.join(config.assets.frontend_assets_path, "packs"))
              config.assets.packs[:packs][:assets] << path
            end
          end

          def build_frontend_pack
            info = state_for(:template_store).each_with_object({}) { |store, combined_info|
              store.layouts.each do |layout_name, _layout|
                layout_key = :"layouts/#{layout_name}"
                combined_info[layout_key] = []

                Pathname.glob(File.join(store.layouts_path, "#{layout_name}.*")) do |path|
                  next if store.template?(path)
                  combined_info[layout_key] << path
                end
              end

              store.paths.each do |path|
                info = store.info(path)

                page_key = :"#{info[:page].logical_path[1..-1]}"
                combined_info[page_key] = []

                (info[:page].find_partials(info[:partials]) + info[:template].find_partials(info[:partials])).each do |used_partial_name|
                  if partial = info[:partials][used_partial_name]
                    Pathname.glob(File.join(config.presenter.path, "#{partial.logical_path}.*")) do |path|
                      next if store.template?(path)
                      combined_info[page_key] << path
                    end
                  end
                end

                Pathname.glob(File.join(info[:page].path.dirname, "#{info[:page].path.basename(info[:page].path.extname)}.*")) do |path|
                  next if store.template?(path)
                  combined_info[page_key] << path
                end
              end
            }

            config.assets.packs[:frontend] = info
          end
        end

        if app.const_defined?(:Renderer)
          app.const_get(:Renderer).class_eval do
            def append_asset_to_head_from_manifest(asset, head, manifest)
              if asset_path = manifest[asset + ".js"]
                head.append("<script src=\"#{asset_path}\"></script>\n")
              end

              if asset_path = manifest[asset + ".css"]
                head.append("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"#{asset_path}\">\n")
              end
            end

            before :render do
              @manifest = if config.assets.manifest_hot_load
                app.load_manifest
              else
                config.assets.manifest
              end

              next unless head = @presenter.view.object.find_significant_nodes(:head)[0]

              if config.assets.polyfills
                head.append(<<~HTML
                  <script>
                    var modernBrowser = (
                      "fetch" in window &&
                      "assign" in Object
                    );
                    if (!modernBrowser) {
                      var scriptElement = document.createElement("script");
                      scriptElement.async = false;
                      scriptElement.src = "#{File.join(config.assets.public_path, "packs/polyfills.js")}";
                      document.head.appendChild(scriptElement);
                    }
                  </script>
                  HTML
                )
              end

              if config.assets.common
                append_asset_to_head_from_manifest("common", head, @manifest)
              end

              (config.assets.autoload + @presenter.view.info(:packs).to_s.split(" ")).uniq.each do |pack|
                append_asset_to_head_from_manifest(File.join("packs", pack.to_s), head, @manifest)
              end

              append_asset_to_head_from_manifest(File.join("frontend", "layouts", @presenter.template.name.to_s), head, @manifest)
              append_asset_to_head_from_manifest(File.join("frontend", @presenter.page.logical_path[1..-1].to_s), head, @manifest)
            end

            after :render do
              if instance_variable_defined?(:@manifest)
                html = res.body.read

                # webpack removes the relative path, so we must too
                frontend_assets_path = config.assets.frontend_assets_path.gsub(File.join(config.app.root, "/"), "")

                @manifest.each do |key, value|
                  if key.start_with?(frontend_assets_path)
                    key = key.gsub(Regexp.new("^#{File.join(frontend_assets_path, "/")}"), "")
                    html.gsub!(Regexp.new("\"/?#{key}\""), value)
                  end
                end

                res.body = StringIO.new(html)
              end
            end
          end
        end
      end
    end
  end
end
