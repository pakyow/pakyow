# frozen_string_literal: true

require "pakyow/support/deprecatable"

require "pakyow/assets/types/sass"

module Pakyow
  module Assets
    module Types
      class Scss < Asset
        extend Support::Deprecatable
        deprecate

        FORMAT = :scss
        include Sass::Behavior
      end
    end
  end
end
