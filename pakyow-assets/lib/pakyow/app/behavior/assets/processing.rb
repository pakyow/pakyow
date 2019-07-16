# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      module Assets
        module Processing
          extend Support::Extension

          apply_extension do
            on "load" do
              if self.class.includes_framework?(:presenter)
                self.class.processor :html do |content|
                  state(:asset).each do |asset|
                    content.gsub!(asset.logical_path, File.join(config.assets.host, asset.public_path))
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
