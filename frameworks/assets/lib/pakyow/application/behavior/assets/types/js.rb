# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/system"

require_relative "../../../../assets/scripts/babel"
require_relative "../../../../assets/scripts/terser"

module Pakyow
  class Application
    module Behavior
      module Assets
        module Types
          module Js
            extend Support::Extension

            apply_extension do
              asset_type :js do
                extension :js

                if Support::System.ruby_version < "2.7.0"
                  def initialize(*)
                    super
                    __common_assets_types_js_initialize
                  end
                else
                  def initialize(*, **)
                    super
                    __common_assets_types_js_initialize
                  end
                end

                private def __common_assets_types_js_initialize
                  @options = @config.babel.to_h

                  if @config.source_maps
                    @options[:source_file_name] = Pathname.new(@local_path).relative_path_from(
                      Pathname.new(Pakyow.config.root)
                    ).to_s
                  end
                end

                def process(content)
                  result = if transformable?
                    transformed = Pakyow::Assets::Scripts::Babel.transform(content, **@options)
                    {content: transformed["code"], map: transformed["map"]}
                  else
                    {content: content, map: ""}
                  end

                  if @config.minify
                    result = minify(result)
                  end

                  @source_map = result[:map]
                  result[:content]
                rescue => error
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
                  filename = Pathname.new(@local_path.to_s).relative_path_from(
                    Pathname.new(Pakyow.config.root)
                  ).to_s

                  options = @config.terser.to_h

                  if @config.source_maps
                    options[:source_map] ||= {}

                    options[:source_map][:filename] = filename

                    unless input[:map].nil? || input[:map].empty?
                      options[:source_map][:include_sources].delete
                      options[:source_map][:content] = input[:map].to_json
                    end
                  else
                    options.delete(:source_map)
                  end

                  result = Pakyow::Assets::Scripts::Terser.minify(
                    {filename => input[:content]}, options
                  )

                  {content: result["code"], map: result["map"]}
                rescue => error
                  Pakyow.logger.error "[#{self.class}] #{error}"

                  # Be sure to return the original input.
                  #
                  input
                end
              end
            end
          end
        end
      end
    end
  end
end
