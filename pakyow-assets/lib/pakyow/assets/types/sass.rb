# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class Sass < Asset
        module Behavior
          extend Support::Extension

          def initialize(local_path:, config:, **kwargs)
            @options = {
              syntax: self.class.const_get("FORMAT"),
              cache: false,
              load_paths: [
                File.dirname(local_path),
                config.path
              ],
              style: config.minify ? :compressed : :nested
            }

            super
          end

          def process(content)
            ::SassC::Engine.new(content, @options).render
          rescue ::SassC::SyntaxError => e
            Pakyow.logger.error "[#{self.class.const_get("FORMAT")}] syntax error: #{e}"
          end

          def dependencies
            engine = ::SassC::Engine.new(File.read(@local_path), @options)
            engine.render

            engine.dependencies.map { |dependency|
              dependency.options[:filename]
            }
          end

          class_methods do
            def load
              unless instance_variable_defined?(:@loaded) && @loaded == true
                require "sassc"
              end
            rescue LoadError
              Pakyow.logger.error <<~ERROR
                Pakyow found a *.#{const_get("FORMAT")} file, but couldn't find sass. Please add this to your Gemfile:

                  gem "sassc"
              ERROR
            ensure
              @loaded = true
            end
          end

          apply_extension do
            extension const_get("FORMAT")
            emits :css
          end
        end

        FORMAT = :sass
        include Behavior
      end
    end
  end
end
