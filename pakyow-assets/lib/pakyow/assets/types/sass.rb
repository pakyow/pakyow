# frozen_string_literal: true

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class Sass < Asset
        class << self
          def load
            require "sass"
          rescue LoadError
            Pakyow.logger.error <<~ERROR
              Pakyow found a *.sass file, but couldn't find sass. Please add this to your Gemfile:

                gem "sass"
            ERROR
          end
        end

        processable
        extension :sass
        emits :css

        def initialize(*)
          super

          @options = {
            syntax: :sass,
            cache: false,
            load_paths: [
              File.dirname(@local_path),
              @source_location
            ]
          }
        end

        def process(content)
          ::Sass::Engine.new(content, @options).render
        rescue ::Sass::SyntaxError => e
          Pakyow.logger.error "[sass] syntax error: #{e}"
        end

        def dependencies
          ::Sass::Engine.for_file(@local_path, @options).dependencies.map { |dependency|
            dependency.options[:filename]
          }
        end
      end
    end
  end
end
