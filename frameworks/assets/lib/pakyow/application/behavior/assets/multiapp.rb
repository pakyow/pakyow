# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Multiapp
          extend Support::Extension

          apply_extension do
            after "configure" do
              next unless Pakyow.multiapp?

              config.assets.paths << Pakyow.config.common_assets_path

              config.assets.packs.paths << Pakyow.config.common_asset_packs_path
            end
          end
        end
      end
    end
  end
end
