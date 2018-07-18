# frozen_string_literal: true

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class ES6 < Asset
        extension :js

        def process(content)
          if external? || !defined?(Babel)
            content
          else
            Babel::Transpiler.transform(content)["code"]
          end
        rescue StandardError => e
          puts e
        end
      end
    end
  end
end
