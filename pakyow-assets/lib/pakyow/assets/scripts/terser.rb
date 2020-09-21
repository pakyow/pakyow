# frozen_string_literal: true

require "pakyow/assets/script"

module Pakyow
  module Assets
    module Scripts
      # Minifies Javascript code using Terser, with support for source maps.
      #
      # @example
      #   code = "function add(first, second) { return first + second; }"
      #
      #   Pakyow::Assets::Scripts::Terser.minify(code)
      #   => { "code" => "function add(n,d){return n+d}" }
      #
      class Terser < Script
        dependency File.expand_path("../../../../../src/source-map@0.6.1/dist/source-map.js", __FILE__)
        dependency File.expand_path("../../../../../src/terser@4.6.10/dist/bundle.min.js", __FILE__)

        function :minify, <<~CODE
          function minify(code, options) {
            return Terser.minify(code, options);
          }
        CODE

        class << self
          def minify(code, options = {})
            super(code, remap_options(options))
          end

          # Terser's options are wildly inconsistent, so remap the configurable ones.
          #
          private def remap_options(options)
            if options.include?(:source_map)
              options[:sourceMap] = options.delete(:source_map)
              if options[:sourceMap].include?(:include_sources)
                options[:sourceMap][:includeSources] = options[:sourceMap].delete(:include_sources)
              end
            end

            options
          end
        end
      end
    end
  end
end
