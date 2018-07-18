# frozen_string_literal: true

require "pakyow/assets/types/sass"

module Pakyow
  module Assets
    module Types
      class Scss < Asset
        FORMAT = :scss
        include Sass::Behavior
      end
    end
  end
end
