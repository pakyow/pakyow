# frozen_string_literal: true

require "json"
require "sassc"

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Types
          module Sass
            module Behavior
              extend Support::Extension

              def initialize(local_path:, config:, **kwargs)
                super

                @options = @config.sass.dup.to_h
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

            extend Support::Extension

            apply_extension do
              asset_type :sass do
                const_set "FORMAT", :sass
                include Behavior
              end
            end
          end
        end
      end
    end
  end
end
