# frozen_string_literal: true

require "rack/proxy"

require "pakyow/assets/types"

# We don't want pakyow to restart the server when an asset changes, since assets handles that itself.
#
# TODO: don't hardcode the public/assets and frontend values
Pakyow.config.server.ignore.concat([
  /public\/assets/,
  /frontend\/assets/,
  /frontend\/.*(#{Pakyow::Assets.extensions.join("|")})/
])

require "pakyow/assets/middleware/proxy"
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
            # builder.map "/assets" do
            #   use Middleware::Proxy
            # end
          end

          settings_for :assets do
            setting :packs, {}
            setting :autoload, [:application]
            setting :polyfills, true
            setting :common, true
            setting :manifest, {}
            setting :manifest_hot_load, false

            defaults :development do
              setting :manifest_hot_load, true
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
            if File.exists?("public/assets/manifest.json")
              JSON.parse(File.read("public/assets/manifest.json"))
            else
              {}
            end
          end

          def build_packs
            config.assets.packs[:packs] = {}

            Dir.glob(File.join(config.app.root, "frontend/assets/packs/*.js")) do |path|
              pack_name = File.basename(path, File.extname(path)).to_sym
              config.assets.packs[:packs][pack_name] = path
            end

            if defined?(Presenter)
              build_frontend_pack
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
                Pathname.glob(File.join(info[:page].path.dirname, "#{info[:page].path.basename(info[:page].path.extname)}.*")) do |path|
                  next if store.template?(path)
                  combined_info[page_key] << path
                end
                combined_info.delete(page_key) if combined_info[page_key].empty?
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
              next unless head = @presenter.view.object.find_significant_nodes(:head)[0]

              manifest = if config.assets.manifest_hot_load
                app.load_manifest
              else
                config.assets.manifest
              end

              if config.assets.polyfills
                # TODO: don't hardcode the polyfills path below
                head.append(<<~HTML
                  <script>
                    var modernBrowser = (
                      "fetch" in window &&
                      "assign" in Object
                    );
                    if (!modernBrowser) {
                      var scriptElement = document.createElement("script");
                      scriptElement.async = false;
                      scriptElement.src = "/assets/packs/polyfills.js";
                      document.head.appendChild(scriptElement);
                    }
                  </script>
                  HTML
                )
              end

              if config.assets.common
                append_asset_to_head_from_manifest("common", head, manifest)
              end

              config.assets.autoload.each do |pack|
                append_asset_to_head_from_manifest(File.join("packs", pack.to_s), head, manifest)
              end

              append_asset_to_head_from_manifest(File.join("frontend", "layouts", @presenter.template.name.to_s), head, manifest)
              append_asset_to_head_from_manifest(File.join("frontend", @presenter.page.logical_path[1..-1].to_s), head, manifest)
            end
          end
        end
      end
    end
  end
end
