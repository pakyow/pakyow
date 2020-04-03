# frozen_string_literal: true

require "pakyow/support/deprecatable"

require "pakyow/assets/scripts/babel"

module Pakyow
  module Assets
    class Babel
      class << self
        extend Support::Deprecatable

        def transform(content, **options)
          Scripts::Babel.transform(content, **options)
        end

        deprecate :transform, solution: "use `Pakyow::Assets::Scripts::Babel::transform'"
      end
    end
  end
end
