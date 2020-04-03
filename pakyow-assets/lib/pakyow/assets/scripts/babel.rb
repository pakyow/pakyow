# frozen_string_literal: true

require "pakyow/assets/script"

module Pakyow
  module Assets
    module Scripts
      # Transforms Javascript using Babel.
      #
      # @example
      #   code = <<~CODE
      #     class Rectangle {
      #       constructor(foo) {
      #         console.log(foo);
      #       }
      #     }
      #   CODE
      #
      #   Pakyow::Assets::Scripts::Babel.transform(code, presets: ["es2015"])
      #   => { code "...", ... }
      #
      class Babel < Script
        dependency File.expand_path("../../../../../src/@babel/standalone@7.9.4/babel.js", __FILE__)

        function :transform, <<~CODE
          function transform(code, options) {
            return Babel.transform(code, options);
          }
        CODE

        class << self
          def transform(code, **options)
            super(code, camelize_keys(options))
          end
        end
      end
    end
  end
end
