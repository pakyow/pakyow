# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../../assets/external"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Externals
          extend Support::Extension

          class_methods do
            def external_script(name, version = nil, package: nil, files: nil)
              assets_config = if ancestors.include?(Plugin)
                parent.config.assets
              else
                config.assets
              end

              assets_config.externals.scripts << Pakyow::Assets::External.new(
                name, version: version, package: package, files: files, config: assets_config
              )
            end

            private def pakyow_js_version
              "^1.1.0-alpha"
            end
          end

          apply_extension do
            after "configure" do
              # Ignore vendored assets since we restart manually.
              #
              Pakyow.ignore File.join(config.assets.externals.path, "**/*")
            end

            after "configure" do
              if config.assets.externals.pakyow
                external_script :pakyow, pakyow_js_version, package: "@pakyow/js", files: [
                  "dist/pakyow.js",
                  "dist/components/confirmable.js",
                  "dist/components/devtools.js",
                  "dist/components/form.js",
                  "dist/components/freshener.js",
                  "dist/components/navigator.js",
                  "dist/components/socket.js",
                  "dist/components/submittable.js"
                ]
              end
            end
          end
        end
      end
    end
  end
end
