# frozen_string_literal: true

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class ES6 < Asset
        class << self
          def load
            require "babel-transpiler"
          rescue LoadError
            Pakyow.logger.error <<~ERROR
              Pakyow found a *.es6 file, but couldn't find babel-transpiler. Please add this to your Gemfile:

                gem "babel-transpiler"
            ERROR
          end
        end

        processable
        extension :es6
        emits :js

        def process(content)
          Babel::Transpiler.transform(content)["code"]
        rescue StandardError => e
          puts e
        end
      end
    end
  end
end
