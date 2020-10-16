# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../../../application/behavior/assets/types/sass"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Types
          module Scss
            extend Support::Extension

            apply_extension do
              asset_type :scss do
                const_set "FORMAT", :scss
                include Sass::Behavior
              end
            end
          end
        end
      end
    end
  end
end
