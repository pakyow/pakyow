# frozen_string_literal: true

require "sassc"

require "pakyow/assets/asset"

module Pakyow
  module Assets
    module Types
      class CSS < Asset
        extension :css

        def initialize(local_path:, config:, **kwargs)
          super

          @options = @config.sass.to_h
          @options[:filename] = @local_path.to_s
          @options[:syntax] = :scss

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

        def source_map_content
          ensure_content
          @engine.source_map
        rescue SassC::NotRenderedError
          nil
        end
      end
    end
  end
end
