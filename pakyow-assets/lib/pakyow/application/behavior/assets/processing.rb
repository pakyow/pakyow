# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Processing
          extend Support::Extension

          apply_extension do
            on "setup" do
              if includes_framework?(:presenter)
                asset_host = if ancestors.include?(Plugin)
                  parent.config.assets.host
                else
                  config.assets.host
                end

                processor :html do |content|
                  assets.each do |asset|
                    content.gsub!(asset.logical_path, File.join(asset_host, asset.public_path))
                  end

                  content
                end
              end
            end
          end
        end
      end
    end
  end
end
