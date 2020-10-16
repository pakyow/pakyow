# frozen_string_literal: true

require "fileutils"

require "pakyow/application"

module Pakyow
  module Assets
    class Precompiler
      def initialize(app)
        @app = app
      end

      def precompile!
        @app.assets.each do |asset|
          precompile_asset!(asset, @app.config.assets.compile_path)
        end

        @app.packs.each do |pack|
          if pack.javascripts?
            precompile_asset!(pack.javascripts, @app.config.assets.compile_path)
          end

          if pack.stylesheets?
            precompile_asset!(pack.stylesheets, @app.config.assets.compile_path)
          end
        end

        if @app.is_a?(Application)
          @app.plugs.each do |plug|
            self.class.new(plug).precompile!
          end
        end
      end

      private

      def precompile_asset!(asset, path)
        compile_path = File.join(path, asset.public_path)

        FileUtils.mkdir_p(File.dirname(compile_path))

        asset_content = asset.each.each_with_object(+"") { |each_asset, content|
          content << each_asset
        }

        File.open(compile_path, "w+") do |file|
          file.write(asset_content)
        end

        if @app.config.assets.source_maps && (source_map = asset.source_map)
          File.open(compile_path + ".map", "w+") do |file|
            file.write(source_map.read)
          end
        end
      end
    end
  end
end
