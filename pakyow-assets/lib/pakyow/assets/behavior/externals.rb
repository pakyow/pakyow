# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/assets/external"

module Pakyow
  module Assets
    module Behavior
      module Externals
        extend Support::Extension

        def external_script(name, version = nil, package: nil, files: nil)
          config.assets.externals.scripts << External.new(
            name, version: version, package: package, files: files, config: config.assets
          )
        end

        apply_extension do
          after :initialize do
            if config.assets.externals.pakyow
              external_script :pakyow, "^1.0.0-alpha.1", package: "@pakyow/js"
            end

            if config.assets.externals.fetch
              config.assets.externals.scripts.each do |external_script|
                unless external_script.exist?
                  external_script.fetch!
                end
              end
            end
          end
        end
      end
    end
  end
end
