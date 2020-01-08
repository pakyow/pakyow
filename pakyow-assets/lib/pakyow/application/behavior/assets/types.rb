# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Types
          extend Support::Extension

          apply_extension do
            require "pakyow/application/behavior/assets/types/js"
            include Js

            require "pakyow/application/behavior/assets/types/css"
            include Css

            require "pakyow/application/behavior/assets/types/sass"
            include Sass

            require "pakyow/application/behavior/assets/types/scss"
            include Scss
          end
        end
      end
    end
  end
end
