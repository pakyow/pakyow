# frozen_string_literal: true

require "pakyow/assets/asset"
require "pakyow/assets/babel"

module Pakyow
  module Assets
    module Types
      class JS < Asset
        extension :js

        def process(content)
          if external?
            content
          else
            Babel.transform(content, @config.babel.to_h)["code"]
          end
        end
      end
    end
  end
end
