# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Assets
    module Behavior
      module Processing
        extend Support::Extension

        apply_extension do
          after :configure do
            if !config.assets.process && self.class.includes_framework?(:presenter)
              self.class.processor :html do |content|
                state_for(:asset).each do |asset|
                  content.gsub!(asset.logical_path, asset.public_path)
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
