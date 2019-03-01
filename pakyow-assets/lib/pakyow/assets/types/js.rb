# frozen_string_literal: true

require "pakyow/assets/asset"
require "pakyow/assets/babel"

require "uglifier"

module Pakyow
  module Assets
    module Types
      class JS < Asset
        extension :js

        def initialize(*)
          super

          @options = @config.babel.to_h

          if @config.source_maps
            @options[:source_file_name] = Pathname.new(@local_path).relative_path_from(
              Pathname.new(Pakyow.config.root)
            ).to_s
          end
        end

        def process(content)
          result = if transformable?
            transformed = Babel.transform(content, @options)
            { content: transformed["code"], map: transformed["map"] }
          else
            { content: content, map: "" }
          end

          if @config.minify
            result = minify(result)
          end

          @source_map = result[:map]
          result[:content]
        rescue StandardError => error
          Pakyow.logger.error "[#{self.class}] #{error}"

          # Be sure to return a string.
          #
          content
        end

        def source_map?
          transformable? || @config.minify
        end

        def source_map_content
          ensure_content
          @source_map
        end

        private

        def transformable?
          !external?
        end

        def minify(input)
          options = @config.uglifier.to_h

          if @config.source_maps
            options[:source_map] ||= {}

            if input[:map].to_s.empty?
              options[:source_map][:filename] = Pathname.new(@local_path.to_s).relative_path_from(
                Pathname.new(Pakyow.config.root)
              ).to_s
            else
              options[:source_map][:input_source_map] = input[:map]
            end
          else
            options.delete(:source_map)
          end

          uglifier = Uglifier.new(options)

          if @config.source_maps
            content, map = uglifier.compile_with_map(input[:content])
            { content: content, map: map }
          else
            { content: uglifier.compile(input[:content]) }
          end
        rescue StandardError => error
          Pakyow.logger.error "[#{self.class}] #{error}"

          # Be sure to return the original input.
          #
          input
        end
      end
    end
  end
end
