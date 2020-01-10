# frozen_string_literal: true

require "json"

require "sassc"

require "pakyow/support/deprecatable"
require "pakyow/support/extension"

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class Sass < Asset
        extend Support::Deprecatable
        deprecate

        module Behavior
          extend Support::Extension

          def initialize(local_path:, config:, **kwargs)
            super

            @options = @config.sass.to_h
            @options[:load_paths] ||= []
            @options[:load_paths].unshift(File.dirname(@local_path))
            @options[:filename] = @local_path.to_s

            # Set the syntax dynamically based on whether we're in Sass or Scss class.
            #
            @options[:syntax] = self.class.const_get("FORMAT")

            if @config.source_maps
              @options[:source_map_file] = File.basename(@local_path.to_s)
            end
          end

          def process(content)
            @engine = ::SassC::Engine.new(content, @options)
            @engine.render
          rescue StandardError => error
            Pakyow.logger.error "[#{self.class}] #{error}"

            # Be sure to return a string.
            #
            content
          end

          def dependencies
            ensure_content
            @engine.dependencies.map { |dependency|
              dependency.options[:filename]
            }
          end

          def source_map_content
            ensure_content
            @engine.source_map
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
