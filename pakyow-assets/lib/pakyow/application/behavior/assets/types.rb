# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Types
          extend Support::Extension

          apply_extension do
            require_relative "types/js"
            include Js

            require_relative "types/css"
            include Css

            require_relative "types/sass"
            include Sass

            require_relative "types/scss"
            include Scss
          end
        end
      end
    end
  end
end
